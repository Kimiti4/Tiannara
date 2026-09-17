"""
Semantic Search - Vector similarity search

Embeds queries in vector space using sentence transformers for
semantic understanding and similar query retrieval.
"""

import logging
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)


@dataclass
class SearchQuery:
    """Represents a search query."""
    text: str
    embedding: Optional[List[float]] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class SearchResult:
    """Result from semantic search."""
    query_text: str
    matches: List[Tuple[str, float]]  # (text, similarity_score)
    total_results: int


class SemanticSearch:
    """Vector similarity search for semantic understanding.
    
    Features:
    - Embed queries in vector space
    - Find similar historical queries
    - Fuzzy matching with configurable thresholds
    - Context retrieval from knowledge base
    
    Example:
        >>> search = SemanticSearch()
        >>> results = search.search("How do I reset password?")
        >>> print(results.matches)
    """
    
    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        self.model_name = model_name
        self.model = None
        self.index = []
        self.documents = []
        self._initialized = False
        
        logger.info(f"Initialized SemanticSearch with model={model_name}")
    
    def initialize(self):
        """Load sentence transformer model."""
        try:
            from sentence_transformers import SentenceTransformer
            self.model = SentenceTransformer(self.model_name)
            self._initialized = True
            logger.info("Sentence transformer model loaded")
        except Exception as e:
            logger.error(f"Failed to load model: {e}")
            raise
    
    def add_document(self, text_or_id: str, text_or_metadata: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None):
        """Add a document to the search index.
        
        Args:
            text_or_id: Either document text OR document ID (if text_or_metadata is provided)
            text_or_metadata: Document text (if text_or_id is ID) OR metadata dict
            metadata: Optional metadata dict (when using 3-argument form)
            
        Supports two calling conventions:
            - add_document("text content")  # Simple form
            - add_document("doc1", "text content")  # With ID
            - add_document("text", {"key": "value"})  # With metadata
        """
        if not self._initialized:
            self.initialize()
        
        # Determine which calling convention is being used
        if text_or_metadata is None:
            # Simple form: add_document(text)
            doc_text = text_or_id
            doc_metadata = metadata or {}
        elif isinstance(text_or_metadata, str):
            # Two-arg form: add_document(doc_id, text)
            doc_text = text_or_metadata
            doc_metadata = {'id': text_or_id}
        else:
            # Two-arg form with metadata: add_document(text, metadata)
            doc_text = text_or_id
            doc_metadata = text_or_metadata
        
        embedding = self.model.encode(doc_text).tolist()
        self.index.append(embedding)
        self.documents.append({'text': doc_text, 'metadata': doc_metadata})
        
        logger.debug(f"Added document to index (total: {len(self.index)})")
    
    def search(self, query: str, top_k: int = 5, threshold: float = 0.3) -> SearchResult:
        """Search for semantically similar documents.
        
        Args:
            query: Search query text
            top_k: Number of results to return
            threshold: Minimum similarity threshold
            
        Returns:
            SearchResult with matches
        """
        if not self._initialized:
            self.initialize()
        
        if not self.index:
            return SearchResult(query_text=query, matches=[], total_results=0)
        
        try:
            # Encode query
            query_embedding = self.model.encode(query).tolist()
            
            # Calculate similarities
            import numpy as np
            
            query_vec = np.array(query_embedding)
            index_vecs = np.array(self.index)
            
            logger.debug(f"Query: '{query}'")
            logger.debug(f"Number of documents: {len(self.documents)}")
            logger.debug(f"Query embedding shape: {query_vec.shape}")
            logger.debug(f"Index embeddings shape: {index_vecs.shape}")
            
            # Cosine similarity
            similarities = np.dot(index_vecs, query_vec) / (
                np.linalg.norm(index_vecs, axis=1) * np.linalg.norm(query_vec)
            )
            
            logger.debug(f"Similarities: {similarities}")
            logger.debug(f"Threshold: {threshold}")
            logger.debug(f"Matches above threshold: {sum(similarities >= threshold)}")
            
            # Get top matches above threshold
            matches = []
            for idx, score in enumerate(similarities):
                if score >= threshold:
                    doc = self.documents[idx]
                    doc_text = doc['text'] if isinstance(doc, dict) else str(doc)
                    matches.append((doc_text, float(score)))
                    logger.debug(f"Match found: '{doc_text}' with score {score:.4f}")
            
            # Sort by similarity
            matches.sort(key=lambda x: x[1], reverse=True)
            matches = matches[:top_k]
            
            result = SearchResult(
                query_text=query,
                matches=matches,
                total_results=len(matches)
            )
            
            logger.debug(f"Found {len(matches)} matches for query")
            return result
            
        except Exception as e:
            logger.error(f"Search failed: {e}")
            return SearchResult(query_text=query, matches=[], total_results=0)
    
    def get_similar_queries(self, query: str, historical_queries: List[str]) -> List[Tuple[str, float]]:
        """Find similar historical queries.
        
        Args:
            query: Current query
            historical_queries: List of past queries
            
        Returns:
            List of (query, similarity) tuples
        """
        # Add historical queries temporarily
        original_index = self.index.copy()
        original_docs = self.documents.copy()
        
        for hist_query in historical_queries:
            self.add_document(hist_query, {'type': 'historical'})
        
        # Search
        result = self.search(query, top_k=10, threshold=0.3)
        
        # Restore original index
        self.index = original_index
        self.documents = original_docs
        
        return result.matches
    
    def remove_document(self, doc_id: str) -> bool:
        """Remove a document from the index.
        
        Args:
            doc_id: Document identifier to remove
            
        Returns:
            True if document was removed, False if not found
        """
        # Find document index by checking text or metadata id
        for i, doc in enumerate(self.documents):
            # Handle both dict and string document formats
            if isinstance(doc, dict):
                doc_text = doc.get('text', '')
                doc_metadata = doc.get('metadata', {})
            else:
                doc_text = str(doc)
                doc_metadata = {}
            
            if doc_metadata.get('id') == doc_id or doc_text == doc_id:
                # Remove from both lists
                self.documents.pop(i)
                if i < len(self.index):
                    self.index.pop(i)
                logger.info(f"Removed document: {doc_id}")
                return True
        
        logger.warning(f"Document not found: {doc_id}")
        return False
    
    def clear(self) -> None:
        """Clear all documents from the index."""
        self.documents.clear()
        self.index.clear()
        logger.info("Cleared all documents from index")
    
    def get_document_count(self) -> int:
        """Get the number of indexed documents.
        
        Returns:
            Number of documents in the index
        """
        return len(self.documents)


# Convenience function
def semantic_search(query: str, documents: List[str]) -> SearchResult:
    """Quick semantic search."""
    search = SemanticSearch()
    for doc in documents:
        search.add_document(doc)
    return search.search(query)
