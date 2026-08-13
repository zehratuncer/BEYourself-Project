// Vercel Serverless Function: /api/instagram
// High-performance, CORS-free server-side resolver for Instagram Reels and Posts.

const https = require('https');
const http = require('http');

function httpRequest(urlStr, headers = {}, timeoutMs = 8000) {
  return new Promise((resolve, reject) => {
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
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept': '*/*',
          ...headers,
        },
      };

      const req = lib.request(options, (res) => {
        // Handle HTTP redirects (301, 302, 307, 308)
        if (
          res.statusCode >= 300 &&
          res.statusCode < 400 &&
          res.headers.location
        ) {
          const redirectUrl = res.headers.location.startsWith('http')
            ? res.headers.location
            : `${url.protocol}//${url.hostname}${res.headers.location}`;
          return resolve(httpRequest(redirectUrl, headers, timeoutMs));
        }

        let body = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          resolve({ statusCode: res.statusCode, body, headers: res.headers });
        });
      });

      req.on('error', (err) => reject(err));
      req.setTimeout(timeoutMs, () => {
        req.destroy();
        reject(new Error(`Timeout after ${timeoutMs}ms`));
      });
      req.end();
    } catch (e) {
      reject(e);
    }
  });
}

function extractShortcode(rawUrl) {
  if (!rawUrl) return null;
  const clean = rawUrl.trim();
  const regex =
    /(?:https?:\/\/)?(?:www\.)?(?:instagram\.com|instagr\.am)\/(?:p|reel|reels|tv|share\/reel|share\/p|share)\/([A-Za-z0-9_-]+)/i;
  const match = clean.match(regex);
  return match && match[1] ? match[1] : null;
}

function cleanHtmlTags(raw) {
  if (!raw) return '';
  return raw
    .replace(/<[^>]*>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .trim();
}

function parseGraphQLMedia(media) {
  const items = [];

  // Carousel
  if (media.edge_sidecar_to_children && media.edge_sidecar_to_children.edges) {
    for (const edge of media.edge_sidecar_to_children.edges) {
      const node = edge.node;
      if (node) {
        if (node.is_video && node.video_url) {
          items.push({ url: node.video_url, isVideo: true });
        } else if (node.display_url) {
          items.push({ url: node.display_url, isVideo: false });
        }
      }
    }
  }

  // Single media
  if (items.length === 0) {
    if (media.is_video && media.video_url) {
      items.push({ url: media.video_url, isVideo: true });
    } else if (media.display_url) {
      items.push({ url: media.display_url, isVideo: false });
    } else if (media.video_url) {
      items.push({ url: media.video_url, isVideo: true });
    }
  }

  // Caption
  let caption = null;
  if (
    media.edge_media_to_caption &&
    media.edge_media_to_caption.edges &&
    media.edge_media_to_caption.edges.length > 0
  ) {
    caption = media.edge_media_to_caption.edges[0]?.node?.text || null;
  }

  // Owner
  const authorUsername = media.owner?.username || null;
  const authorFullName = media.owner?.full_name || null;

  if (items.length > 0) {
    return { mediaItems: items, caption, authorUsername, authorFullName };
  }
  return null;
}

module.exports = async function handler(req, res) {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,POST');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  const url = req.query.url || req.body?.url;
  if (!url) {
    return res.status(400).json({
      success: false,
      error: 'url parameter is required (e.g. ?url=https://www.instagram.com/reel/...)',
    });
  }

  const shortcode = extractShortcode(url);
  if (!shortcode) {
    return res.status(400).json({
      success: false,
      error: 'Geçersiz veya tanınmayan Instagram bağlantısı.',
    });
  }

  // Strategy 1: GraphQL Multi-DocID Queries
  const docIds = ['10015901848480474', '8845758582119845', '7479768652077977'];
  for (const docId of docIds) {
    try {
      const gqlUrl = `https://www.instagram.com/graphql/query/?doc_id=${docId}&variables=${encodeURIComponent(
        JSON.stringify({ shortcode })
      )}`;
      const response = await httpRequest(gqlUrl, {
        'X-IG-App-ID': '936619743392459',
        'X-Requested-With': 'XMLHttpRequest',
      }, 5000);

      if (response.statusCode === 200) {
        const json = JSON.parse(response.body);
        const media =
          json?.data?.xdt_shortcode_media || json?.data?.shortcode_media;
        if (media) {
          const parsed = parseGraphQLMedia(media);
          if (parsed && parsed.mediaItems.length > 0) {
            return res.status(200).json({
              success: true,
              shortcode,
              ...parsed,
            });
          }
        }
      }
    } catch (e) {
      // Continue to next docId
    }
  }

  // Strategy 2: Web API JSON (__d=dis / __a=1)
  try {
    const webUrl = `https://www.instagram.com/p/${shortcode}/?__a=1&__d=dis`;
    const response = await httpRequest(webUrl, {
      'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
      'X-IG-App-ID': '936619743392459',
    }, 4500);

    if (response.statusCode === 200) {
      const json = JSON.parse(response.body);
      const media =
        json?.graphql?.shortcode_media ||
        (json?.items && json.items.length > 0 ? json.items[0] : null);
      if (media) {
        const parsed = parseGraphQLMedia(media);
        if (parsed && parsed.mediaItems.length > 0) {
          return res.status(200).json({
            success: true,
            shortcode,
            ...parsed,
          });
        }
      }
    }
  } catch (e) {}

  // Strategy 3: Embed page scraper
  try {
    const embedUrl = `https://www.instagram.com/p/${shortcode}/embed/captioned/`;
    const response = await httpRequest(embedUrl, {}, 5000);
    if (response.statusCode === 200) {
      const html = response.body;
      const embedItems = [];

      const videoMatch =
        html.match(/<video[^>]+src="([^">]+)"/) ||
        html.match(/class="EmbeddedMediaVideo"[^>]+src="([^">]+)"/);
      if (videoMatch && videoMatch[1]) {
        embedItems.push({
          url: videoMatch[1].replace(/&amp;/g, '&'),
          isVideo: true,
        });
      }

      if (embedItems.length === 0) {
        const imgMatches = html.matchAll(
          /<img[^>]+(?:class="EmbeddedMediaImage"|class="EmbeddedVideoPosterImage")[^>]+src="([^">]+)"/g
        );
        for (const m of imgMatches) {
          if (m[1]) {
            embedItems.push({
              url: m[1].replace(/&amp;/g, '&'),
              isVideo: false,
            });
          }
        }
      }

      const captionMatch = html.match(/<div class="Caption"[^>]*>([\s\S]*?)<\/div>/i);
      const caption = captionMatch ? cleanHtmlTags(captionMatch[1]) : null;

      const userMatch = html.match(/<a class="UsernameText"[^>]*>([\s\S]*?)<\/a>/i);
      const authorUsername = userMatch ? cleanHtmlTags(userMatch[1]) : null;

      if (embedItems.length > 0) {
        return res.status(200).json({
          success: true,
          shortcode,
          mediaItems: embedItems,
          caption,
          authorUsername,
          authorFullName: authorUsername,
        });
      }
    }
  } catch (e) {}

  // Strategy 4: oEmbed API
  try {
    const oembedUrl = `https://www.instagram.com/api/v1/oembed/?url=https://www.instagram.com/p/${shortcode}/`;
    const response = await httpRequest(oembedUrl, {}, 4000);
    if (response.statusCode === 200) {
      const json = JSON.parse(response.body);
      if (json.thumbnail_url) {
        return res.status(200).json({
          success: true,
          shortcode,
          mediaItems: [{ url: json.thumbnail_url, isVideo: false }],
          caption: json.title || null,
          authorUsername: json.author_name || null,
          authorFullName: json.author_name || null,
        });
      }
    }
  } catch (e) {}

  // Failed all strategies
  return res.status(404).json({
    success: false,
    error:
      'Medya indirilemedi. Gönderi gizli bir hesaba ait olabilir veya Instagram bu bağlantıyı kısıtlamış olabilir.',
  });
};
