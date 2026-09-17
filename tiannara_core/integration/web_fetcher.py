"""
Web Data Fetcher Module - Internet Access for Tiannara

Provides comprehensive web data ingestion capabilities:
- HTTP/HTTPS requests (GET, POST, PUT, DELETE)
- Web scraping with HTML parsing
- Search engine integration
- RSS/news feed reading
- REST API consumption
- Rate limiting and caching
- Error handling and retries
"""

import asyncio
import json
import time
from typing import Dict, List, Optional, Any, Union
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from urllib.parse import urljoin, urlparse

import httpx
from bs4 import BeautifulSoup


@dataclass
class FetchResult:
    """Result from a web fetch operation"""
    url: str
    success: bool
    status_code: Optional[int] = None
    content_type: Optional[str] = None
    text_content: Optional[str] = None
    html_content: Optional[str] = None
    json_data: Optional[Dict] = None
    headers: Dict[str, str] = field(default_factory=dict)
    response_time_ms: float = 0.0
    error: Optional[str] = None
    timestamp: datetime = field(default_factory=datetime.now)
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'url': self.url,
            'success': self.success,
            'status_code': self.status_code,
            'content_type': self.content_type,
            'text_content': self.text_content[:500] if self.text_content else None,
            'json_data': self.json_data,
            'response_time_ms': self.response_time_ms,
            'error': self.error,
            'timestamp': self.timestamp.isoformat(),
        }


@dataclass  
class SearchResult:
    """Result from a search operation"""
    query: str
    results: List[Dict[str, str]]
    total_results: int = 0
    search_engine: str = ""
    timestamp: datetime = field(default_factory=datetime.now)


@dataclass
class RSSFeedItem:
    """Single item from RSS feed"""
    title: str
    link: str
    description: str
    published: Optional[str] = None
    author: Optional[str] = None
    categories: List[str] = field(default_factory=list)


class WebDataFetcher:
    """
    Comprehensive web data fetching and scraping engine.
    
    Features:
    - Async HTTP client with connection pooling
    - Automatic retries with exponential backoff
    - Request rate limiting
    - Response caching
    - HTML parsing and text extraction
    - JSON API consumption
    - RSS feed parsing
    - Search engine integration
    
    Usage:
        fetcher = WebDataFetcher()
        
        # Fetch webpage
        result = await fetcher.fetch_url("https://example.com")
        
        # Extract text
        text = await fetcher.extract_text("https://example.com/article")
        
        # Call API
        data = await fetcher.fetch_json("https://api.example.com/data")
        
        # Search web
        results = await fetcher.search_web("python programming")
    """
    
    def __init__(
        self,
        timeout: float = 30.0,
        max_retries: int = 3,
        rate_limit_rps: float = 10.0,  # Requests per second
        cache_ttl: int = 300,  # Cache TTL in seconds
        user_agent: str = "Tiannara-Bot/1.0"
    ):
        """
        Initialize WebDataFetcher.
        
        Args:
            timeout: Request timeout in seconds
            max_retries: Maximum retry attempts
            rate_limit_rps: Rate limit (requests per second)
            cache_ttl: Cache time-to-live in seconds
            user_agent: User agent string
        """
        self.timeout = timeout
        self.max_retries = max_retries
        self.rate_limit_rps = rate_limit_rps
        self.cache_ttl = cache_ttl
        
        # HTTP client with connection pooling
        self.client = httpx.AsyncClient(
            timeout=httpx.Timeout(timeout),
            headers={
                "User-Agent": user_agent,
                "Accept": "text/html,application/xhtml+xml,application/json,*/*",
            },
            follow_redirects=True,
        )
        
        # Rate limiting
        self._request_times: List[float] = []
        
        # Simple in-memory cache
        self._cache: Dict[str, tuple] = {}  # url -> (result, timestamp)
        
        # Statistics
        self.total_requests = 0
        self.successful_requests = 0
        self.failed_requests = 0
    
    async def fetch_url(
        self,
        url: str,
        method: str = "GET",
        headers: Optional[Dict[str, str]] = None,
        params: Optional[Dict] = None,
        json_body: Optional[Dict] = None,
        use_cache: bool = True
    ) -> FetchResult:
        """
        Fetch URL content with automatic retries and rate limiting.
        
        Args:
            url: URL to fetch
            method: HTTP method (GET, POST, etc.)
            headers: Additional headers
            params: Query parameters
            json_body: JSON body for POST/PUT
            use_cache: Whether to use cache
            
        Returns:
            FetchResult with response data
        """
        # Check cache
        if use_cache and url in self._cache:
            cached_result, cached_time = self._cache[url]
            if time.time() - cached_time < self.cache_ttl:
                return cached_result
        
        # Apply rate limiting
        await self._apply_rate_limit()
        
        start_time = time.time()
        
        for attempt in range(self.max_retries):
            try:
                # Prepare request
                request_headers = self.client.headers.copy()
                if headers:
                    request_headers.update(headers)
                
                # Make request
                response = await self.client.request(
                    method=method.upper(),
                    url=url,
                    headers=request_headers,
                    params=params,
                    json=json_body,
                )
                
                response_time = (time.time() - start_time) * 1000
                
                # Parse response
                content_type = response.headers.get("content-type", "").lower()
                
                result = FetchResult(
                    url=url,
                    success=response.status_code < 400,
                    status_code=response.status_code,
                    content_type=content_type,
                    headers=dict(response.headers),
                    response_time_ms=response_time,
                )
                
                # Parse content based on type
                if "application/json" in content_type:
                    try:
                        result.json_data = response.json()
                    except:
                        result.text_content = response.text
                elif "text/html" in content_type or "text/plain" in content_type:
                    result.html_content = response.text
                    result.text_content = self._extract_text_from_html(response.text)
                else:
                    result.text_content = response.text
                
                # Update statistics
                self.total_requests += 1
                if result.success:
                    self.successful_requests += 1
                else:
                    self.failed_requests += 1
                
                # Cache successful results
                if use_cache and result.success:
                    self._cache[url] = (result, time.time())
                
                return result
                
            except httpx.TimeoutException as e:
                error_msg = f"Timeout after {self.timeout}s"
                if attempt == self.max_retries - 1:
                    return FetchResult(
                        url=url,
                        success=False,
                        error=error_msg,
                        response_time_ms=(time.time() - start_time) * 1000
                    )
                
            except httpx.HTTPError as e:
                error_msg = f"HTTP error: {str(e)}"
                if attempt == self.max_retries - 1:
                    return FetchResult(
                        url=url,
                        success=False,
                        error=error_msg,
                        response_time_ms=(time.time() - start_time) * 1000
                    )
                
                # Wait before retry (exponential backoff)
                await asyncio.sleep(2 ** attempt)
        
        # Should not reach here
        return FetchResult(url=url, success=False, error="Unknown error")
    
    async def extract_text(self, url: str, use_cache: bool = True) -> Optional[str]:
        """
        Extract readable text from a webpage.
        
        Args:
            url: URL to extract text from
            use_cache: Whether to use cache
            
        Returns:
            Extracted text content or None
        """
        result = await self.fetch_url(url, use_cache=use_cache)
        
        if result.success and result.html_content:
            return self._extract_text_from_html(result.html_content)
        
        return result.text_content
    
    async def fetch_json(
        self,
        url: str,
        params: Optional[Dict] = None,
        headers: Optional[Dict[str, str]] = None,
        use_cache: bool = True
    ) -> Optional[Dict]:
        """
        Fetch and parse JSON from API endpoint.
        
        Args:
            url: API endpoint URL
            params: Query parameters
            headers: Additional headers
            use_cache: Whether to use cache
            
        Returns:
            Parsed JSON data or None
        """
        result = await self.fetch_url(
            url,
            params=params,
            headers=headers,
            use_cache=use_cache
        )
        
        return result.json_data if result.success else None
    
    async def post_json(
        self,
        url: str,
        data: Dict,
        headers: Optional[Dict[str, str]] = None
    ) -> Optional[Dict]:
        """
        POST JSON data to API endpoint.
        
        Args:
            url: API endpoint URL
            data: JSON data to send
            headers: Additional headers
            
        Returns:
            Response JSON data or None
        """
        result = await self.fetch_url(
            url,
            method="POST",
            json_body=data,
            headers=headers,
            use_cache=False  # Don't cache POST requests
        )
        
        return result.json_data if result.success else None
    
    async def search_web(
        self,
        query: str,
        num_results: int = 5,
        engine: str = "duckduckgo"
    ) -> SearchResult:
        """
        Search the web using various search engines.
        
        Args:
            query: Search query
            num_results: Number of results to return
            engine: Search engine (duckduckgo, google, bing)
            
        Returns:
            SearchResult with list of results
        """
        if engine == "duckduckgo":
            return await self._search_duckduckgo(query, num_results)
        elif engine == "google":
            return await self._search_google(query, num_results)
        elif engine == "bing":
            return await self._search_bing(query, num_results)
        else:
            raise ValueError(f"Unsupported search engine: {engine}")
    
    async def fetch_rss_feed(self, url: str) -> List[RSSFeedItem]:
        """
        Fetch and parse RSS feed.
        
        Args:
            url: RSS feed URL
            
        Returns:
            List of RSSFeedItem objects
        """
        try:
            import feedparser
        except ImportError:
            raise ImportError("feedparser is required for RSS feeds. Install with: pip install feedparser")
        
        result = await self.fetch_url(url)
        
        if not result.success or not result.text_content:
            return []
        
        # Parse RSS feed
        feed = feedparser.parse(result.text_content)
        
        items = []
        for entry in feed.entries[:10]:  # Limit to 10 items
            item = RSSFeedItem(
                title=entry.get('title', ''),
                link=entry.get('link', ''),
                description=entry.get('description', entry.get('summary', '')),
                published=entry.get('published', ''),
                author=entry.get('author', ''),
                categories=[tag.term for tag in entry.get('tags', [])],
            )
            items.append(item)
        
        return items
    
    async def scrape_table(self, url: str, table_index: int = 0) -> List[Dict[str, str]]:
        """
        Scrape HTML table from webpage.
        
        Args:
            url: URL containing table
            table_index: Index of table to scrape (0-based)
            
        Returns:
            List of dictionaries representing table rows
        """
        result = await self.fetch_url(url)
        
        if not result.success or not result.html_content:
            return []
        
        soup = BeautifulSoup(result.html_content, 'html.parser')
        tables = soup.find_all('table')
        
        if table_index >= len(tables):
            return []
        
        table = tables[table_index]
        rows = table.find_all('tr')
        
        if not rows:
            return []
        
        # Extract headers
        headers = []
        header_row = rows[0].find_all(['th', 'td'])
        for i, cell in enumerate(header_row):
            headers.append(cell.get_text(strip=True) or f"column_{i}")
        
        # Extract data rows
        data = []
        for row in rows[1:]:
            cells = row.find_all('td')
            if len(cells) == len(headers):
                row_data = {}
                for header, cell in zip(headers, cells):
                    row_data[header] = cell.get_text(strip=True)
                data.append(row_data)
        
        return data
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get fetcher statistics"""
        return {
            'total_requests': self.total_requests,
            'successful_requests': self.successful_requests,
            'failed_requests': self.failed_requests,
            'success_rate': (
                self.successful_requests / self.total_requests * 100
                if self.total_requests > 0 else 0
            ),
            'cache_size': len(self._cache),
        }
    
    async def close(self):
        """Close HTTP client"""
        await self.client.aclose()
    
    async def __aenter__(self):
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.close()
    
    # Private methods
    
    async def _apply_rate_limit(self):
        """Apply rate limiting"""
        now = time.time()
        
        # Remove old timestamps
        self._request_times = [
            t for t in self._request_times
            if now - t < 1.0
        ]
        
        # Check if we need to wait
        if len(self._request_times) >= self.rate_limit_rps:
            wait_time = 1.0 - (now - self._request_times[0])
            if wait_time > 0:
                await asyncio.sleep(wait_time)
        
        self._request_times.append(time.time())
    
    def _extract_text_from_html(self, html: str) -> str:
        """Extract readable text from HTML"""
        soup = BeautifulSoup(html, 'html.parser')
        
        # Remove scripts and styles
        for script in soup(["script", "style", "nav", "footer", "header"]):
            script.decompose()
        
        # Get text
        text = soup.get_text(separator='\n', strip=True)
        
        # Clean up whitespace
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        return '\n'.join(lines)
    
    async def _search_duckduckgo(self, query: str, num_results: int) -> SearchResult:
        """Search using DuckDuckGo (no API key required)"""
        # DuckDuckGo HTML search
        url = "https://html.duckduckgo.com/html/"
        params = {"q": query}
        
        result = await self.fetch_url(url, params=params)
        
        if not result.success or not result.html_content:
            return SearchResult(query=query, results=[])
        
        soup = BeautifulSoup(result.html_content, 'html.parser')
        results = []
        
        for result_div in soup.select('.result')[:num_results]:
            title_elem = result_div.select_one('.result__title')
            snippet_elem = result_div.select_one('.result__snippet')
            
            if title_elem:
                title = title_elem.get_text(strip=True)
                link = title_elem.get('href', '')
                snippet = snippet_elem.get_text(strip=True) if snippet_elem else ''
                
                results.append({
                    'title': title,
                    'link': link,
                    'snippet': snippet,
                })
        
        return SearchResult(
            query=query,
            results=results,
            total_results=len(results),
            search_engine='duckduckgo'
        )
    
    async def _search_google(self, query: str, num_results: int) -> SearchResult:
        """Search using Google Custom Search API (requires API key)"""
        api_key = None  # TODO: Get from environment/config
        cx = None  # TODO: Get from environment/config
        
        if not api_key or not cx:
            raise ValueError("Google Custom Search requires API_KEY and CX configuration")
        
        url = "https://www.googleapis.com/customsearch/v1"
        params = {
            "key": api_key,
            "cx": cx,
            "q": query,
            "num": min(num_results, 10),
        }
        
        data = await self.fetch_json(url, params=params)
        
        if not data:
            return SearchResult(query=query, results=[])
        
        results = []
        for item in data.get('items', []):
            results.append({
                'title': item.get('title', ''),
                'link': item.get('link', ''),
                'snippet': item.get('snippet', ''),
            })
        
        return SearchResult(
            query=query,
            results=results,
            total_results=int(data.get('searchInformation', {}).get('totalResults', 0)),
            search_engine='google'
        )
    
    async def _search_bing(self, query: str, num_results: int) -> SearchResult:
        """Search using Bing Search API (requires API key)"""
        api_key = None  # TODO: Get from environment/config
        
        if not api_key:
            raise ValueError("Bing Search requires API_KEY configuration")
        
        url = "https://api.bing.microsoft.com/v7.0/search"
        headers = {"Ocp-Apim-Subscription-Key": api_key}
        params = {"q": query, "count": num_results}
        
        data = await self.fetch_json(url, headers=headers, params=params)
        
        if not data:
            return SearchResult(query=query, results=[])
        
        results = []
        for item in data.get('webPages', {}).get('value', []):
            results.append({
                'title': item.get('name', ''),
                'link': item.get('url', ''),
                'snippet': item.get('snippet', ''),
            })
        
        return SearchResult(
            query=query,
            results=results,
            total_results=int(data.get('webPages', {}).get('totalEstimatedMatches', 0)),
            search_engine='bing'
        )
