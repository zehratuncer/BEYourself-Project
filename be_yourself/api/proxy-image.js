// Vercel Serverless Function: /api/proxy-image
// High-performance CORS proxy for Instagram CDN images and media streams.

const https = require('https');
const http = require('http');

function fetchMediaStream(urlStr, reqHeaders = {}, maxRedirects = 5) {
  return new Promise((resolve, reject) => {
    if (maxRedirects < 0) {
      return reject(new Error('Too many redirects'));
    }

    try {
      const url = new URL(urlStr);
      const isHttps = url.protocol === 'https:';
      const lib = isHttps ? https : http;

      const options = {
        hostname: url.hostname,
        port: url.port || (isHttps ? 443 : 80),
        path: url.pathname + url.search,
        method: 'GET',
        headers: {
          'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1',
          'Accept':
            'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
          'Referer': 'https://www.instagram.com/',
          ...reqHeaders,
        },
      };

      const req = lib.request(options, (res) => {
        if (
          res.statusCode >= 300 &&
          res.statusCode < 400 &&
          res.headers.location
        ) {
          const redirectUrl = res.headers.location.startsWith('http')
            ? res.headers.location
            : `${url.protocol}//${url.hostname}${res.headers.location}`;
          return resolve(fetchMediaStream(redirectUrl, reqHeaders, maxRedirects - 1));
        }

        const chunks = [];
        res.on('data', (chunk) => chunks.push(chunk));
        res.on('end', () => {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            data: Buffer.concat(chunks),
          });
        });
      });

      req.on('error', (err) => reject(err));
      req.setTimeout(12000, () => {
        req.destroy();
        reject(new Error('Media fetch timeout'));
      });
      req.end();
    } catch (e) {
      reject(e);
    }
  });
}

module.exports = async function handler(req, res) {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  const rawUrl = req.query.url || req.query.src;
  if (!rawUrl) {
    return res.status(400).json({ error: 'url parameter is required' });
  }

  const cleanUrl = decodeURIComponent(rawUrl)
    .replace(/&amp;/g, '&')
    .replace(/\\u0026/g, '&')
    .trim();

  try {
    const result = await fetchMediaStream(cleanUrl);

    if (result.statusCode === 200 && result.data && result.data.length > 0) {
      const contentType =
        result.headers['content-type'] || 'image/jpeg';
      res.setHeader('Content-Type', contentType);
      res.setHeader(
        'Cache-Control',
        'public, max-age=86400, s-maxage=86400, stale-while-revalidate=604800'
      );
      res.setHeader('Content-Length', result.data.length);
      return res.status(200).end(result.data);
    } else {
      // Retry without referer
      const retryResult = await fetchMediaStream(cleanUrl, {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      });
      if (retryResult.statusCode === 200 && retryResult.data && retryResult.data.length > 0) {
        const contentType =
          retryResult.headers['content-type'] || 'image/jpeg';
        res.setHeader('Content-Type', contentType);
        res.setHeader(
          'Cache-Control',
          'public, max-age=86400, s-maxage=86400, stale-while-revalidate=604800'
        );
        res.setHeader('Content-Length', retryResult.data.length);
        return res.status(200).end(retryResult.data);
      }
      return res.status(result.statusCode || 500).json({ error: 'Failed to fetch media' });
    }
  } catch (e) {
    return res.status(500).json({ error: e.message || 'Internal proxy error' });
  }
};
