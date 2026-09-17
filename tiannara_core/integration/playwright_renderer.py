"""
Playwright Integration - JavaScript Rendering for Dynamic Web Pages

Enables Tiannara to:
- Render JavaScript-heavy websites (React, Vue, Angular SPAs)
- Execute dynamic content loading
- Handle infinite scroll, lazy loading
- Take screenshots of rendered pages
- Interact with web elements (click, type, scroll)
- Extract data from complex web applications

Why this matters:
-----------------
Traditional HTTP requests can't execute JavaScript. Modern websites use:
- Single Page Applications (SPAs) - content loads via JS
- Infinite scroll - load more on scroll
- Lazy loading - images/content load on demand
- Authentication flows - login required
- Interactive elements - forms, buttons, dropdowns

Playwright solves this by using a real browser engine.
"""

import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)


@dataclass
class RenderResult:
    """Result from page rendering"""
    url: str
    success: bool
    html_content: str = ""
    text_content: str = ""
    screenshot_path: Optional[str] = None
    response_time_ms: float = 0.0
    status_code: Optional[int] = None
    error: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


class PlaywrightRenderer:
    """
    JavaScript-enabled web page renderer using Playwright.
    
    Usage:
        renderer = PlaywrightRenderer()
        
        # Render a SPA
        result = await renderer.render_page("https://example.com")
        
        # Render with interaction
        result = await renderer.render_with_interaction(
            "https://example.com",
            actions=[
                {"action": "click", "selector": "#load-more"},
                {"action": "wait", "time": 2}
            ]
        )
        
        # Take screenshot
        result = await renderer.screenshot("https://example.com", "output.png")
    """
    
    def __init__(self, headless: bool = True):
        """
        Initialize Playwright renderer.
        
        Args:
            headless: Run browser in headless mode (no UI)
        """
        self.headless = headless
        self.browser = None
        self.context = None
        self.available = False
        
        try:
            self._check_playwright()
        except Exception as e:
            logger.warning(f"Playwright not available: {e}")
    
    def _check_playwright(self):
        """Check if Playwright is installed"""
        try:
            from playwright.async_api import async_playwright
            self.playwright_import = async_playwright
            self.available = True
            logger.info("Playwright initialized")
        except ImportError:
            raise ImportError(
                "Playwright not installed. Install with:\n"
                "  pip install playwright\n"
                "  playwright install chromium"
            )
    
    async def __aenter__(self):
        """Async context manager entry"""
        await self.initialize()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        await self.close()
    
    async def initialize(self):
        """Initialize browser"""
        if not self.available:
            raise RuntimeError("Playwright not available")
        
        playwright = await self.playwright_import().start()
        self.browser = await playwright.chromium.launch(headless=self.headless)
        self.context = await self.browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        )
        
        logger.info("Browser initialized")
    
    async def close(self):
        """Close browser"""
        if self.context:
            await self.context.close()
        if self.browser:
            await self.browser.close()
        logger.info("Browser closed")
    
    async def render_page(
        self,
        url: str,
        wait_for_selector: Optional[str] = None,
        wait_time: float = 2.0,
        timeout: int = 30000
    ) -> RenderResult:
        """
        Render a JavaScript-heavy webpage.
        
        Args:
            url: URL to render
            wait_for_selector: CSS selector to wait for before capturing
            wait_time: Additional wait time after load (seconds)
            timeout: Page load timeout (milliseconds)
            
        Returns:
            RenderResult with HTML, text, metadata
        """
        import time
        start_time = time.time()
        
        try:
            page = await self.context.new_page()
            
            # Navigate to page
            response = await page.goto(url, timeout=timeout, wait_until='networkidle')
            
            # Wait for specific element if specified
            if wait_for_selector:
                await page.wait_for_selector(wait_for_selector, timeout=timeout)
            
            # Additional wait for dynamic content
            if wait_time > 0:
                await page.wait_for_timeout(wait_time * 1000)
            
            # Extract content
            html_content = await page.content()
            text_content = await page.inner_text('body') or ""
            
            # Get page metadata
            title = await page.title()
            status_code = response.status if response else None
            
            elapsed = (time.time() - start_time) * 1000
            
            result = RenderResult(
                url=url,
                success=True,
                html_content=html_content,
                text_content=text_content,
                response_time_ms=elapsed,
                status_code=status_code,
                metadata={
                    'title': title,
                    'viewport': {'width': 1920, 'height': 1080}
                }
            )
            
            await page.close()
            return result
        
        except Exception as e:
            elapsed = (time.time() - start_time) * 1000
            logger.error(f"Error rendering {url}: {e}")
            
            return RenderResult(
                url=url,
                success=False,
                response_time_ms=elapsed,
                error=str(e)
            )
    
    async def render_with_interaction(
        self,
        url: str,
        actions: List[Dict[str, Any]],
        timeout: int = 60000
    ) -> RenderResult:
        """
        Render page and perform interactions (click, type, scroll).
        
        Args:
            url: URL to render
            actions: List of actions to perform
                Example: [
                    {"action": "click", "selector": "#button"},
                    {"action": "type", "selector": "#input", "text": "hello"},
                    {"action": "scroll", "direction": "down"},
                    {"action": "wait", "time": 2}
                ]
            timeout: Total timeout (milliseconds)
            
        Returns:
            RenderResult after interactions
        """
        import time
        start_time = time.time()
        
        try:
            page = await self.context.new_page()
            await page.goto(url, timeout=timeout, wait_until='networkidle')
            
            # Execute actions
            for action in actions:
                action_type = action.get('action', '').lower()
                
                if action_type == 'click':
                    selector = action.get('selector', '')
                    await page.click(selector, timeout=5000)
                
                elif action_type == 'type':
                    selector = action.get('selector', '')
                    text = action.get('text', '')
                    await page.fill(selector, text)
                
                elif action_type == 'scroll':
                    direction = action.get('direction', 'down')
                    amount = action.get('amount', 500)
                    
                    if direction == 'down':
                        await page.evaluate(f"window.scrollBy(0, {amount})")
                    elif direction == 'up':
                        await page.evaluate(f"window.scrollBy(0, -{amount})")
                
                elif action_type == 'wait':
                    wait_ms = action.get('time', 1) * 1000
                    await page.wait_for_timeout(wait_ms)
                
                elif action_type == 'hover':
                    selector = action.get('selector', '')
                    await page.hover(selector)
                
                elif action_type == 'select':
                    selector = action.get('selector', '')
                    value = action.get('value', '')
                    await page.select_option(selector, value)
            
            # Wait for any final updates
            await page.wait_for_timeout(1000)
            
            # Extract content
            html_content = await page.content()
            text_content = await page.inner_text('body') or ""
            title = await page.title()
            
            elapsed = (time.time() - start_time) * 1000
            
            result = RenderResult(
                url=url,
                success=True,
                html_content=html_content,
                text_content=text_content,
                response_time_ms=elapsed,
                metadata={
                    'title': title,
                    'actions_performed': len(actions)
                }
            )
            
            await page.close()
            return result
        
        except Exception as e:
            elapsed = (time.time() - start_time) * 1000
            logger.error(f"Error during interaction: {e}")
            
            return RenderResult(
                url=url,
                success=False,
                response_time_ms=elapsed,
                error=str(e)
            )
    
    async def screenshot(
        self,
        url: str,
        output_path: str,
        full_page: bool = True,
        wait_time: float = 2.0
    ) -> RenderResult:
        """
        Take a screenshot of a rendered page.
        
        Args:
            url: URL to capture
            output_path: Path to save screenshot
            full_page: Capture entire scrollable page
            wait_time: Wait time before capture (seconds)
            
        Returns:
            RenderResult with screenshot path
        """
        import time
        start_time = time.time()
        
        try:
            page = await self.context.new_page()
            await page.goto(url, wait_until='networkidle')
            
            if wait_time > 0:
                await page.wait_for_timeout(wait_time * 1000)
            
            # Take screenshot
            await page.screenshot(path=output_path, full_page=full_page)
            
            elapsed = (time.time() - start_time) * 1000
            
            result = RenderResult(
                url=url,
                success=True,
                screenshot_path=output_path,
                response_time_ms=elapsed,
                metadata={'full_page': full_page}
            )
            
            await page.close()
            return result
        
        except Exception as e:
            elapsed = (time.time() - start_time) * 1000
            logger.error(f"Error taking screenshot: {e}")
            
            return RenderResult(
                url=url,
                success=False,
                response_time_ms=elapsed,
                error=str(e)
            )
    
    async def extract_dynamic_content(
        self,
        url: str,
        selectors: List[str],
        wait_time: float = 3.0
    ) -> Dict[str, str]:
        """
        Extract specific elements from dynamically loaded content.
        
        Args:
            url: URL to extract from
            selectors: CSS selectors to extract
            wait_time: Wait time for content to load
            
        Returns:
            Dictionary mapping selectors to their text content
        """
        try:
            page = await self.context.new_page()
            await page.goto(url, wait_until='networkidle')
            
            if wait_time > 0:
                await page.wait_for_timeout(wait_time * 1000)
            
            results = {}
            for selector in selectors:
                try:
                    element = await page.query_selector(selector)
                    if element:
                        text = await element.inner_text()
                        results[selector] = text.strip()
                    else:
                        results[selector] = None
                except Exception as e:
                    logger.warning(f"Failed to extract {selector}: {e}")
                    results[selector] = None
            
            await page.close()
            return results
        
        except Exception as e:
            logger.error(f"Error extracting content: {e}")
            return {sel: None for sel in selectors}
    
    async def handle_infinite_scroll(
        self,
        url: str,
        max_scrolls: int = 10,
        scroll_pause: float = 1.0
    ) -> RenderResult:
        """
        Handle infinite scroll pages (like social media feeds).
        
        Args:
            url: URL with infinite scroll
            max_scrolls: Maximum number of scrolls
            scroll_pause: Pause between scrolls (seconds)
            
        Returns:
            RenderResult with all loaded content
        """
        import time
        start_time = time.time()
        
        try:
            page = await self.context.new_page()
            await page.goto(url, wait_until='networkidle')
            
            # Scroll down multiple times
            for i in range(max_scrolls):
                await page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
                await page.wait_for_timeout(scroll_pause * 1000)
                
                # Check if we've reached the bottom
                reached_bottom = await page.evaluate("""
                    () => {
                        return (window.innerHeight + window.scrollY) >= document.body.offsetHeight;
                    }
                """)
                
                if reached_bottom:
                    logger.info(f"Reached bottom after {i+1} scrolls")
                    break
            
            # Extract all content
            html_content = await page.content()
            text_content = await page.inner_text('body') or ""
            
            elapsed = (time.time() - start_time) * 1000
            
            result = RenderResult(
                url=url,
                success=True,
                html_content=html_content,
                text_content=text_content,
                response_time_ms=elapsed,
                metadata={
                    'scrolls_performed': max_scrolls,
                    'infinite_scroll': True
                }
            )
            
            await page.close()
            return result
        
        except Exception as e:
            elapsed = (time.time() - start_time) * 1000
            logger.error(f"Error handling infinite scroll: {e}")
            
            return RenderResult(
                url=url,
                success=False,
                response_time_ms=elapsed,
                error=str(e)
            )
