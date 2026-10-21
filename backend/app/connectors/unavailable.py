from app.connectors.base import BaseConnector, ConnectorStatus


class UnavailableConnector(BaseConnector):
    """An explicit missing integration, never a fabricated price source."""
    def get_status(self):
        return ConnectorStatus.REQUIRES_SETUP, 'لم يُربط مصدر أسعار موثوق لهذا المتجر بعد'

    def get_fees_info(self, district=None):
        return dict(base_delivery_fee_halalas=None, service_fee_halalas=None,
                    free_delivery_threshold_halalas=None, min_order_halalas=None)

    async def search(self, query, district=None):
        return []
