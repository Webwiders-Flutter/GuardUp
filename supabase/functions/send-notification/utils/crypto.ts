/**
 * Cryptographic helpers for Google OAuth 2.0 Web Crypto RSA-SHA256
 */

export function base64UrlEncode(input: Uint8Array | string): string {
  let str = "";
  if (typeof input === "string") {
    str = btoa(input);
  } else {
    let binary = "";
    const len = input.byteLength;
    for (let i = 0; i < len; i++) {
      binary += String.fromCharCode(input[i]);
    }
    str = btoa(binary);
  }
  return str.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export function pemToBinary(pem: string): Uint8Array {
  const cleanPem = pem
    .replace(/-----BEGIN[ A-Z0-9_-]+-----/g, "")
    .replace(/-----END[ A-Z0-9_-]+-----/g, "")
    .replace(/\\n/g, "")
    .replace(/\s+/g, "");

  const binaryString = atob(cleanPem);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}

export async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const binaryDer = pemToBinary(pem);
  return await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );
}

export async function signJwtWithWebCrypto(
  header: Record<string, unknown>,
  payload: Record<string, unknown>,
  privateKeyPem: string,
): Promise<string> {
  const encHeader = base64UrlEncode(JSON.stringify(header));
  const encPayload = base64UrlEncode(JSON.stringify(payload));
  const dataToSign = `${encHeader}.${encPayload}`;

  const cryptoKey = await importPrivateKey(privateKeyPem);
  const encoder = new TextEncoder();
  const signatureBytes = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(dataToSign),
  );

  const encSignature = base64UrlEncode(new Uint8Array(signatureBytes));
  return `${dataToSign}.${encSignature}`;
}
