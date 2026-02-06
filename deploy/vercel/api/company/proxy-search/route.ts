// app/api/company/proxy-search/route.ts
// API normalization: wraps upstream response in {found:boolean, data:...} format
// Deploy to: www.bizagent.sk/api/company/proxy-search

import { NextRequest, NextResponse } from 'next/server';

export const runtime = 'edge';

type ProxySearchResponse = 
  | { found: true; data: Record<string, unknown> }
  | { found: false; error: string; ico: string; retryAfter?: number };

export async function GET(request: NextRequest): Promise<NextResponse<ProxySearchResponse>> {
  const rawIco = request.nextUrl.searchParams.get('ico') || '';
  
  // Normalize: pad to 8 digits
  const icoNorm = rawIco.replace(/\D/g, '').padStart(8, '0');
  
  // Validate: must be exactly 8 digits after normalization
  if (!/^\d{8}$/.test(icoNorm)) {
    return NextResponse.json(
      { found: false, error: 'Invalid ICO format', ico: rawIco },
      { status: 400 }
    );
  }

  try {
    // Call existing upstream (ORSR proxy endpoint)
    const upstreamUrl = process.env.ICO_UPSTREAM_URL || 'https://icoatlas.sk';
    const response = await fetch(`${upstreamUrl}/api/company/${icoNorm}`, {
      headers: {
        'Accept': 'application/json',
        'X-ICO-LOOKUP-CONTRACT': '1.0.0',
      },
    });

    // Rate limited
    if (response.status === 429) {
      const retryAfter = parseInt(response.headers.get('Retry-After') || '60', 10);
      return NextResponse.json(
        { found: false, error: 'Rate limited', ico: icoNorm, retryAfter },
        { 
          status: 429,
          headers: { 'Retry-After': String(retryAfter) },
        }
      );
    }

    // Not found (404 or empty response)
    if (response.status === 404) {
      return NextResponse.json(
        { found: false, error: 'Company not found', ico: icoNorm },
        { status: 200 }  // Widget-friendly: 200 + found:false
      );
    }

    // Server error
    if (!response.ok) {
      return NextResponse.json(
        { found: false, error: 'Upstream error', ico: icoNorm },
        { status: response.status }
      );
    }

    const data = await response.json();
    
    // Check if upstream returned "not found" in body
    if (!data || !data.name || data.error === 'Company not found') {
      return NextResponse.json(
        { found: false, error: 'Company not found', ico: icoNorm },
        { status: 200 }
      );
    }

    // Success: wrap in {found:true, data:...}
    return NextResponse.json({ found: true, data }, { status: 200 });

  } catch (error) {
    console.error('Proxy search error:', error);
    return NextResponse.json(
      { found: false, error: 'Service unavailable', ico: icoNorm },
      { status: 503 }
    );
  }
}

/*
═══════════════════════════════════════════════════════════════════════════════
  CURL TESTS (after deploy to www.bizagent.sk)
═══════════════════════════════════════════════════════════════════════════════

# Test 1: Valid ICO (ESET)
curl -s 'https://www.bizagent.sk/api/company/proxy-search?ico=31333532' | jq
# Expected: {"found":true,"data":{"ico":"31333532","name":"ESET, spol. s r.o.",...}}

# Test 2: Short ICO (auto-padded)
curl -s 'https://www.bizagent.sk/api/company/proxy-search?ico=123456' | jq
# Expected: {"found":false,"error":"Company not found","ico":"00123456"}

# Test 3: Nonexistent ICO
curl -s 'https://www.bizagent.sk/api/company/proxy-search?ico=99999999' | jq
# Expected: {"found":false,"error":"Company not found","ico":"99999999"}
# HTTP Status: 200

# Test 4: Invalid format (letters)
curl -s -w '\nHTTP:%{http_code}' 'https://www.bizagent.sk/api/company/proxy-search?ico=ABC'
# Expected: {"found":false,"error":"Invalid ICO format","ico":"ABC"}
# HTTP Status: 400

# Test 5: Empty ICO
curl -s -w '\nHTTP:%{http_code}' 'https://www.bizagent.sk/api/company/proxy-search?ico='
# Expected: {"found":false,"error":"Invalid ICO format","ico":""}
# HTTP Status: 400

# Test 6: No ICO param
curl -s -w '\nHTTP:%{http_code}' 'https://www.bizagent.sk/api/company/proxy-search'
# Expected: {"found":false,"error":"Invalid ICO format","ico":""}
# HTTP Status: 400

═══════════════════════════════════════════════════════════════════════════════
*/
