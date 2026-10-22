import {searchAmazonPublic} from './reader.mjs';

// Public product pages only: no proxy, cookies, account, paid API, or retries.
// First verify the reader on this host before enabling any periodic collection.
const products=[];
for(const query of ['نوتيلا','نسكافيه']) {
  try {
    const found=await searchAmazonPublic(query,fetch);
    products.push(...found);
    console.log(JSON.stringify({query,products:found.map(p=>({asin:p.retailer_product_id,title:p.name_ar,offers:p.offers.map(o=>({price:o.price_sar,kind:o.price_kind,checked_at:o.last_verified_at,source:o.source_url}))}))}));
  }catch(e){
    console.log(JSON.stringify({query,error:e.message}));
    if(/retailer_http_(?:401|403|429)|retailer_challenge/.test(e.message))break;
  }
}
console.log(JSON.stringify({observed_products:products.length}));
