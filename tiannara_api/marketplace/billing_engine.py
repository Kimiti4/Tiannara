"""
Billing Engine - Subscription billing and invoice generation

Handles recurring billing, usage-based charges, payment processing,
and invoice generation for API marketplace subscriptions.
"""

import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum

logger = logging.getLogger(__name__)


class BillingPeriod(Enum):
    """Billing periods."""
    MONTHLY = "monthly"
    QUARTERLY = "quarterly"
    ANNUALLY = "annually"


class InvoiceStatus(Enum):
    """Invoice status."""
    DRAFT = "draft"
    PENDING = "pending"
    PAID = "paid"
    OVERDUE = "overdue"
    CANCELLED = "cancelled"


@dataclass
class Invoice:
    """Billing invoice."""
    invoice_id: str
    subscription_id: str
    user_id: str
    amount: float
    currency: str = "USD"
    status: InvoiceStatus = InvoiceStatus.DRAFT
    issue_date: datetime = field(default_factory=datetime.now)
    due_date: Optional[datetime] = None
    paid_date: Optional[datetime] = None
    line_items: List[Dict[str, Any]] = field(default_factory=list)


class BillingEngine:
    """Subscription billing and invoice management.
    
    Features:
    - Recurring billing automation
    - Usage-based charge calculation
    - Multi-currency support
    - Invoice generation and tracking
    - Payment status management
    """
    
    def __init__(self):
        self.invoices: Dict[str, Invoice] = {}
        self.tier_pricing: Dict[str, float] = {
            'free': 0.0,
            'basic': 29.99,
            'pro': 99.99,
            'enterprise': 499.99
        }
        self.overage_rate: float = 0.001  # $0.001 per request over quota
        
    def generate_invoice(
        self,
        subscription_id: str,
        user_id: str,
        tier: str,
        usage_count: int,
        quota: int,
        billing_period: BillingPeriod = BillingPeriod.MONTHLY
    ) -> Invoice:
        """Generate an invoice for a subscription.
        
        Args:
            subscription_id: Subscription identifier
            user_id: User identifier
            tier: Subscription tier
            usage_count: Total API calls made
            quota: Monthly quota
            billing_period: Billing period
            
        Returns:
            Generated invoice
        """
        import secrets
        invoice_id = f"inv_{secrets.token_hex(8)}"
        
        # Calculate base charge
        base_charge = self.tier_pricing.get(tier, 0.0)
        
        # Calculate overage charges
        overage = max(0, usage_count - quota)
        overage_charge = overage * self.overage_rate
        
        total_amount = base_charge + overage_charge
        
        # Apply billing period multiplier
        if billing_period == BillingPeriod.QUARTERLY:
            total_amount *= 3
        elif billing_period == BillingPeriod.ANNUALLY:
            total_amount *= 12
        
        # Create line items
        line_items = [
            {
                'description': f'{tier.title()} Tier Subscription',
                'quantity': 1,
                'unit_price': base_charge,
                'amount': base_charge
            }
        ]
        
        if overage > 0:
            line_items.append({
                'description': f'Overage Charges ({overage} requests)',
                'quantity': overage,
                'unit_price': self.overage_rate,
                'amount': overage_charge
            })
        
        invoice = Invoice(
            invoice_id=invoice_id,
            subscription_id=subscription_id,
            user_id=user_id,
            amount=round(total_amount, 2),
            status=InvoiceStatus.PENDING,
            due_date=datetime.now() + timedelta(days=30),
            line_items=line_items
        )
        
        self.invoices[invoice_id] = invoice
        logger.info(f"Invoice generated: {invoice_id} for ${total_amount:.2f}")
        
        return invoice
    
    def mark_invoice_paid(self, invoice_id: str):
        """Mark an invoice as paid.
        
        Args:
            invoice_id: Invoice identifier
        """
        invoice = self.invoices.get(invoice_id)
        if not invoice:
            raise ValueError(f"Invoice not found: {invoice_id}")
        
        invoice.status = InvoiceStatus.PAID
        invoice.paid_date = datetime.now()
        
        logger.info(f"Invoice paid: {invoice_id}")
    
    def get_user_invoices(self, user_id: str, status: Optional[InvoiceStatus] = None) -> List[Invoice]:
        """Get invoices for a user.
        
        Args:
            user_id: User identifier
            status: Optional status filter
            
        Returns:
            List of invoices
        """
        user_invoices = [
            inv for inv in self.invoices.values()
            if inv.user_id == user_id
        ]
        
        if status:
            user_invoices = [inv for inv in user_invoices if inv.status == status]
        
        return user_invoices
    
    def get_overdue_invoices(self) -> List[Invoice]:
        """Get all overdue invoices.
        
        Returns:
            List of overdue invoices
        """
        now = datetime.now()
        
        return [
            inv for inv in self.invoices.values()
            if inv.status == InvoiceStatus.PENDING and inv.due_date and inv.due_date < now
        ]
    
    def calculate_revenue(self, start_date: datetime, end_date: datetime) -> Dict[str, Any]:
        """Calculate revenue for a period.
        
        Args:
            start_date: Period start
            end_date: Period end
            
        Returns:
            Revenue summary
        """
        period_invoices = [
            inv for inv in self.invoices.values()
            if inv.status == InvoiceStatus.PAID and 
               start_date <= inv.paid_date <= end_date
        ]
        
        total_revenue = sum(inv.amount for inv in period_invoices)
        
        return {
            'period': {
                'start': start_date.isoformat(),
                'end': end_date.isoformat()
            },
            'total_invoices': len(period_invoices),
            'paid_invoices': len(period_invoices),
            'total_revenue': round(total_revenue, 2),
            'average_invoice': round(total_revenue / len(period_invoices), 2) if period_invoices else 0
        }
