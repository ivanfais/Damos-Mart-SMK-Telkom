const rawOrigin = (import.meta.env.VITE_API_URL || 'https://damos-mart-smk-telkom-production.up.railway.app').trim();
const apiOrigin = rawOrigin.replace(/\/$/, '');

export const API_ORIGIN = apiOrigin;
export const API_BASE_URL = `${apiOrigin}/api/v1`;
export const SOCKET_SERVER_URL = apiOrigin;

export function assetUrl(path: string | null | undefined): string {
  if (!path) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return `${apiOrigin}${path.startsWith('/') ? path : `/${path}`}`;
}
