//#region lib/quantity.mjs
var UNITS = "كيلو\\s*جرام|كيلوجرام|كيلو|كجم|كغم|كغ|kg|جرام|غرام|جم|غم|grams?|gm|g|ملليلتر|مليلتر|ml|مل|لتر|liters?|litres?|ltr|l";
var COUNTS = "عبوات|عبوه|علب|علبه|حبات|حبه|قطع|قطعه|حفاضات|حفاضه|حفاض|مناديل|منديل|pieces?|pcs?|counts?|ct|diapers?|sheets?|wipes?|tablets?|capsules?|bottles?|cans?|sachets?";
new RegExp("\\d+(?:\\.\\d+)?\\s*(?:" + UNITS + ")(?![a-z\\u0600-\\u06ff])", "gi");
var countPattern = new RegExp("(\\d+)\\s*(" + COUNTS + ")(?![a-z\\u0600-\\u06ff])", "i");
function arithmetic(s) {
	const tokens = s.replace(/(?:free|مجانا|مجاني)/g, "").replace(/[x×]/g, "*").match(/\d+|[+*()]/g) || [];
	let i = 0;
	const atom = () => {
		if (tokens[i] === "(") {
			i++;
			const n = sum();
			if (tokens[i++] !== ")") throw Error();
			return n;
		}
		const n = Number(tokens[i++]);
		if (!Number.isSafeInteger(n) || n < 1) throw Error();
		return n;
	};
	const mul = () => {
		let n = atom();
		while (tokens[i] === "*") {
			i++;
			n *= atom();
		}
		return n;
	};
	const sum = () => {
		let n = mul();
		while (tokens[i] === "+") {
			i++;
			n += mul();
		}
		return n;
	};
	try {
		const n = sum();
		return i === tokens.length && Number.isSafeInteger(n) && n > 0 && n <= 1e4 ? n : null;
	} catch {
		return null;
	}
}
var convert = (amount, u) => {
	u = u.replace(/\s/g, "");
	if ([
		"كيلوجرام",
		"كيلو",
		"كجم",
		"كغم",
		"كغ",
		"kg"
	].includes(u)) return [amount * 1e3, "g"];
	if ([
		"لتر",
		"l",
		"ltr",
		"liter",
		"litre",
		"liters",
		"litres"
	].includes(u)) return [amount * 1e3, "ml"];
	return [amount, [
		"مل",
		"ml",
		"ملليلتر",
		"مليلتر"
	].includes(u) ? "ml" : "g"];
};
function readQuantity(value) {
	let text = normalize(value);
	if (/(?:diapers?|nappies|حفاضات|حفاضه|حفاض)/i.test(text) && text.match(countPattern)) text = text.replace(/* @__PURE__ */ new RegExp("(?:\\d+(?:\\.\\d+)?\\s*[-–]\\s*)?\\d+(?:\\.\\d+)?\\s*(?:kg|كيلو(?:\\s*جرام)?|كجم)(?![a-z\\u0600-\\u06ff])", "gi"), " ");
	const uncertain = (status) => ({
		amount: null,
		unit: null,
		pack: null,
		status
	});
	if (new RegExp("\\d+(?:\\.\\d+)?\\s*(?:(?:" + UNITS + ")\\s*)?(?:[-–—]|to|الي)\\s*\\d+(?:\\.\\d+)?\\s*(?:كيلو\\s*جرام|كيلوجرام|كيلو|كجم|كغم|كغ|kg|جرام|غرام|جم|غم|grams?|gm|g|ملليلتر|مليلتر|ml|مل|لتر|liters?|litres?|ltr|l)(?![a-z\\u0600-\\u06ff])", "i").test(text)) return uncertain("range");
	text = text.replace(/(\d+(?:\.\d+)?)\s*\+\s*(\d+(?:\.\d+)?)/g, (_, a, b) => String(Number(a) + Number(b)) + " ");
	const matches = [...text.matchAll(new RegExp("(\\d+(?:\\.\\d+)?)\\s*(" + UNITS + ")(?![a-z\\u0600-\\u06ff])", "gi"))];
	if (matches.length > 1 && /[&]|\b(?:plus|with free)\b|\sو\s/.test(text.slice(matches[0].index + matches[0][0].length, matches.at(-1).index))) return uncertain("mixed");
	const sizes = matches.map((m) => convert(Number(m[1]), m[2]));
	if (new Set(sizes.map((s) => s.join(":"))).size > 1) return uncertain("conflicting");
	let m = matches[0], amount = sizes[0]?.[0] ?? null, unit = sizes[0]?.[1] ?? null;
	if (!m) {
		m = text.match(countPattern);
		if (m) {
			amount = Number(m[1]);
			unit = "count";
		}
	}
	let pack = null;
	if (m) {
		const before = text.slice(0, m.index), after = text.slice(m.index + m[0].length);
		const prefix = before.replace(/[()]/g, " ").match(/(\d+(?:\s*[x×*]\s*\d+)*\s*[x×*]\s*)$/i);
		if (prefix) pack = arithmetic(prefix[1].replace(/[x×*]\s*$/, ""));
		const suffix = after.match(/^\s*\)*\s*[x×*]\s*(\(?\s*\d+(?:\s*[+*x×]\s*\(?\s*\d+\s*\)?)*(?:\s*free)?\s*\)?)/i);
		if (suffix) {
			const n = arithmetic(suffix[1]);
			if (n) pack = (pack || 1) * n;
		}
	}
	if (unit !== "count") {
		const count = text.match(countPattern) || text.match(new RegExp("(?:^|\\s)(?:حزمه|كرتون|شده|pack)\\s*(?:of\\s*)?\\(?\\s*(\\d+)(?![\\d.]|\\s*(?:" + UNITS + "))", "i"));
		if (count) {
			const n = Number(count[1]);
			if (pack && n !== pack) return uncertain("conflicting");
			pack = n;
		}
	}
	if (!pack && /(?:multi\s*pack|multipack|عبوه متعدده|عبوات متعدده)/i.test(text)) return uncertain("unknown_pack");
	return {
		amount,
		unit,
		pack
	};
}
function quantityFields(size) {
	return {
		normalized_size_amount: size.amount,
		normalized_size_unit: size.unit,
		pack_count: size.pack || 1,
		pack_type: size.pack > 1 ? "bundle" : "single",
		quantity_status: size.status || (size.amount > 0 ? "exact" : "unknown")
	};
}
//#endregion
//#region lib/store-directory.mjs
var STORES = {
	danube: {
		name: "الدانوب",
		origin: "https://danube.sa",
		search: "/search?query=",
		live: true
	},
	panda: {
		name: "بنده",
		origin: "https://panda.sa",
		search: "/ar/plp?search_key=",
		live: true
	},
	tamimi: {
		name: "التميمي",
		origin: "https://shop.tamimimarkets.com",
		search: "/search?query=",
		live: true,
		english: true
	},
	carrefour: {
		name: "كارفور",
		origin: "https://www.carrefourksa.com",
		search: "/mafsau/en/search?keyword=",
		live: true,
		english: true
	},
	alam_alwisam: {
		name: "عالم الوسام",
		origin: "https://alam-alwisam.com",
		search: "/search?q=",
		live: true
	},
	amazon: {
		name: "أمازون السعودية",
		origin: "https://www.amazon.sa",
		category: "marketplace",
		live: true,
		price_provider: "صفحات أمازون",
		supports_alerts: false
	},
	bindawood: {
		name: "بن داوود",
		origin: "https://www.bindawood.sa",
		search: "/search?query=",
		live: true
	},
	nahdi: {
		name: "صيدلية النهدي",
		origin: "https://www.nahdionline.com",
		website: "/ar-sa",
		search: "/ar-sa/search?query=",
		category: "pharmacy",
		live: true
	},
	dawaa: {
		name: "صيدلية الدواء",
		origin: "https://www.al-dawaa.com",
		website: "/ar/",
		search: "/ar/search/",
		category: "pharmacy",
		live: true
	},
	lemon: {
		name: "صيدلية ليمون",
		origin: "https://lemon.sa",
		search: "/index.php?route=product/search&search=",
		category: "pharmacy",
		live: true
	},
	united: {
		name: "صيدلية المتحدة",
		origin: "https://unitedpharmacy.sa",
		website: "/ar/",
		search: "/ar/catalogsearch/result/?q=",
		category: "pharmacy",
		live: true
	},
	ninja: {
		name: "نينجا",
		live: false
	},
	hungerstation: {
		name: "هنقرستيشن",
		live: false
	},
	keeta: {
		name: "كيتا",
		live: false
	},
	amazon_now: {
		name: "أمازون ناو",
		live: false
	},
	othaim: {
		name: "العثيم",
		origin: "https://www.othaimmarkets.com",
		website: "/ar",
		live: false,
		reason: "نشرات عروض متاحة؛ أسعار المنتجات غير متاحة للمقارنة حاليًا"
	},
	noon_minutes: {
		name: "نون منتس",
		live: false
	}
};
Object.keys(STORES).filter((code) => STORES[code].live);
//#endregion
//#region lib/free-price-collector.mjs
var HOUR = 36e5;
var statement = (db, sql, args = []) => db.prepare(sql).bind(...args);
var safeError = (e) => /^(?:retailer_http_\d{3}|retailer_challenge|product_identity_mismatch|catalog_format_changed|catalog_too_large|cross_origin_redirect|redirect_limit)$/.test(e?.message || "") ? e.message : e?.name === "TimeoutError" || e?.name === "AbortError" ? "timeout" : "retailer_unavailable";
function unexpiredProducts(products, at = Date.now()) {
	return products.map((p) => ({
		...p,
		offers: (p.offers || []).filter((o) => {
			const checked = Date.parse(o.last_verified_at), expiry = Date.parse(o.price_expires_at);
			return o.price_verified && o.price_halalas > 0 && Number.isFinite(checked) && checked <= at && at - checked < 24 * HOUR && (!o.price_expires_at || Number.isFinite(expiry) && expiry > at);
		})
	})).filter((p) => p.offers.length);
}
async function collectPublicPrices(db, query, collect, { provider = "pricena", namespace = "" } = {}) {
	if (!db) return collect();
	const bytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(query));
	const digest = Array.from(new Uint8Array(bytes), (b) => b.toString(16).padStart(2, "0")).join("");
	const key = (namespace || "free-amazon:v1") + ":" + digest, at = Date.now();
	const cooldown = namespace ? namespace + ":cooldown" : "free-price-cooldown", lock = namespace ? namespace + ":lock" : "free-price-lock";
	const cached = await statement(db, "SELECT data FROM search_cache WHERE key=? AND expires>?", [key, at]).first();
	if (cached) try {
		return unexpiredProducts(JSON.parse(cached.data), at);
	} catch {}
	if (await statement(db, "SELECT value FROM state WHERE key=? AND expires>?", [cooldown, at]).first()) throw Error("collector_cooldown");
	const lease = crypto.randomUUID();
	if ((await statement(db, "INSERT INTO state(key,value,expires) VALUES(?,?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value,expires=excluded.expires WHERE state.expires<? RETURNING value", [
		lock,
		lease,
		at + 25e3,
		at
	]).first())?.value !== lease) throw Error("collector_busy");
	const status = async (value) => statement(db, "INSERT INTO state(key,value,expires) VALUES(?,?,0) ON CONFLICT(key) DO UPDATE SET value=excluded.value,expires=0", ["free-price-last", JSON.stringify({
		provider,
		...value,
		checked_at: (/* @__PURE__ */ new Date()).toISOString()
	})]).run();
	try {
		const again = await statement(db, "SELECT data FROM search_cache WHERE key=? AND expires>?", [key, Date.now()]).first();
		if (again) return unexpiredProducts(JSON.parse(again.data));
		if (await statement(db, "SELECT value FROM state WHERE key=? AND expires>?", [cooldown, Date.now()]).first()) throw Error("collector_cooldown");
		const products = unexpiredProducts(await collect()), checked = Date.now();
		const expiry = Math.min(checked + (products.length ? HOUR : 10 * 6e4), ...products.flatMap((p) => p.offers.map((o) => Date.parse(o.price_expires_at) || checked + HOUR)));
		await statement(db, "INSERT INTO search_cache(key,data,expires) VALUES(?,?,?) ON CONFLICT(key) DO UPDATE SET data=excluded.data,expires=excluded.expires", [
			key,
			JSON.stringify(products),
			expiry
		]).run();
		await status({
			status: products.length ? "observed_prices" : "no_fresh_prices",
			products_count: products.length
		});
		await statement(db, "INSERT INTO state(key,value,expires) VALUES(?,?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value,expires=excluded.expires", [
			cooldown,
			"spacing",
			checked + 1e4
		]).run();
		return products;
	} catch (e) {
		if (e?.message === "collector_cooldown") throw e;
		const failure = safeError(e), delay = /retailer_http_(?:401|403)|retailer_challenge/.test(failure) ? HOUR : 5 * 6e4;
		await status({
			status: "temporarily_unavailable",
			failure_code: failure,
			products_count: 0
		});
		await statement(db, "INSERT INTO state(key,value,expires) VALUES(?,?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value,expires=excluded.expires", [
			cooldown,
			failure,
			Date.now() + delay
		]).run();
		throw Error(failure);
	} finally {
		await statement(db, "DELETE FROM state WHERE key=? AND value=?", [lock, lease]).run();
	}
}
//#endregion
//#region lib/product-identity.mjs
var TERMS = {
	"@fat:full": [
		"كامل الدسم",
		"كاملة الدسم",
		"full fat",
		"full cream",
		"whole milk"
	],
	"@fat:low": [
		"قليل الدسم",
		"قليلة الدسم",
		"low fat",
		"reduced fat",
		"semi skimmed"
	],
	"@fat:skimmed": [
		"خالي الدسم",
		"خالية الدسم",
		"منزوع الدسم",
		"skimmed",
		"skim",
		"fat free",
		"non fat"
	],
	"@process:fresh": [
		"طازج",
		"طازجة",
		"fresh",
		"مبستر",
		"مبسترة",
		"pasteurized",
		"pasteurised"
	],
	"@process:uht": [
		"طويل الاجل",
		"طويلة الاجل",
		"طويل الامد",
		"طويل الصلاحية",
		"long life",
		"longlife",
		"uht"
	],
	"@form:powder": [
		"حليب مجفف",
		"milk powder",
		"powdered milk"
	],
	"@form:evaporated": ["حليب مبخر", "evaporated milk"],
	"@form:condensed": ["حليب مكثف", "condensed milk"],
	"@flavour:strawberry": [
		"فراولة",
		"بالفراولة",
		"strawberry"
	],
	"@flavour:vanilla": [
		"فانيلا",
		"فانيليا",
		"بالفانيلا",
		"vanilla"
	],
	"@flavour:chocolate": [
		"شوكولاتة",
		"الشوكولاتة",
		"شوكولاتا",
		"شوكولا",
		"بالشوكولاتة",
		"chocolate",
		"cocoa",
		"كاكاو",
		"بالكاكاو"
	],
	"@flavour:hazelnut": [
		"بندق",
		"بالبندق",
		"hazelnut",
		"hazelnuts"
	],
	"@flavour:banana": [
		"موز",
		"بالموز",
		"banana"
	],
	"@flavour:mango": [
		"مانجو",
		"بالمانجو",
		"mango"
	],
	"@flavour:orange": [
		"برتقال",
		"بالبرتقال",
		"orange"
	],
	"@diet:lactose_free": [
		"خالي من اللاكتوز",
		"خال من اللاكتوز",
		"خالي اللاكتوز",
		"lactose free"
	],
	"@diet:sugar_free": [
		"خالي من السكر",
		"خالي السكر",
		"بدون سكر",
		"sugar free",
		"zero sugar"
	],
	"@diet:no_added_sugar": [
		"بدون سكر مضاف",
		"بدون اضافة سكر",
		"no added sugar",
		"no sugar added"
	],
	"@diet:organic": [
		"عضوي",
		"عضوية",
		"organic"
	],
	"@diet:protein": [
		"عالي البروتين",
		"غني بالبروتين",
		"high protein",
		"protein plus"
	],
	"@kind:soft_drink": [
		"carbonated soft drink",
		"carbonated drinks",
		"carbonated drink",
		"carbonated soft drinks",
		"carbonated beverage",
		"soft drinks",
		"soft drink",
		"cola",
		"soda",
		"مشروب غازي",
		"مشروبات غازية",
		"المشروبات الغازية",
		"كولا"
	],
	"@variant:regular": [
		"regular",
		"عادي",
		"العادي",
		"عادية"
	],
	"@variant:diet": ["دايت", "diet"],
	"@variant:zero": [
		"زيرو سكر",
		"زيرو",
		"zero"
	],
	"@variant:max": ["ماكس", "max"],
	"@container:can": [
		"علبة",
		"علب",
		"can",
		"cans"
	],
	"@container:bottle": [
		"زجاجة",
		"قنينة",
		"bottle",
		"bottles"
	],
	"@material:glass": ["زجاج", "glass"],
	"@material:plastic": [
		"بلاستيك",
		"بلاستيكية",
		"plastic",
		"pet"
	],
	"@flavour:cream": ["كريمة", "cream"],
	"@flavour:lemon": [
		"ليمون",
		"بالليمون",
		"lemon"
	],
	"@flavour:apple": [
		"تفاح",
		"بالتفاح",
		"apple"
	],
	"@flavour:mint": [
		"نعناع",
		"بالنعناع",
		"mint"
	],
	"@flavour:berries": [
		"توت",
		"بالتوت",
		"berries",
		"berry"
	],
	"@flavour:caramel": ["كراميل", "caramel"],
	"@flavour:strawberry": [
		"فراولة",
		"بالفراولة",
		"strawberry",
		"strawberries"
	],
	"@kind:diapers": [
		"حفاضات",
		"حفاض",
		"حفاضة",
		"diapers",
		"diaper",
		"nappies",
		"nappy"
	],
	"@kind:detergent": [
		"مسحوق غسيل",
		"مسحوق الغسيل",
		"laundry detergent",
		"washing powder",
		"detergent"
	],
	"@kind:tissue": [
		"مناديل",
		"tissues",
		"tissue"
	],
	"@kind:pasta": [
		"معكرونة",
		"مكرونة",
		"pasta"
	],
	"@kind:shampoo": ["شامبو", "shampoo"],
	"@kind:soap": ["صابون", "soap"],
	"@kind:eggs": [
		"بيض",
		"eggs",
		"egg"
	],
	"@kind:chicken": ["دجاج", "chicken"],
	"@kind:beans": [
		"فاصوليا",
		"فول",
		"beans",
		"bean"
	],
	"@kind:bread": [
		"خبز",
		"توست",
		"bread",
		"toast"
	],
	"@kind:milk": ["حليب", "milk"],
	"@kind:laban": ["لبن", "laban"],
	"@kind:yogurt": [
		"زبادي",
		"زباديه",
		"yoghurt",
		"yogurt"
	],
	"@kind:labneh": [
		"لبنة",
		"labneh",
		"labnah"
	],
	"@kind:spread": [
		"معجون",
		"كريمة قابلة للدهن",
		"قابل للدهن",
		"spread",
		"spreads"
	],
	"@kind:biscuits": [
		"بسكويت",
		"biscuits",
		"biscuit"
	],
	"@kind:juice": ["عصير", "juice"],
	"@kind:water": [
		"مياه شرب",
		"مياه الشرب",
		"مياه شرب معباه",
		"drinking water",
		"bottled water",
		"ماء",
		"مياه",
		"water"
	],
	"@kind:rice": [
		"ارز",
		"رز",
		"rice"
	],
	"@kind:oil": ["زيت", "oil"],
	"@kind:cheese": [
		"جبن",
		"جبنة",
		"cheese"
	],
	"@kind:tea": ["شاي", "tea"],
	"@kind:coffee": ["قهوة", "coffee"],
	"@kind:sugar": ["سكر", "sugar"]
};
var clean = (x) => normalize(x).normalize("NFKD").replace(/[\u0300-\u036f]/g, "").replace(/[^\p{L}\p{N}.%]+/gu, " ").replace(/\s+/g, " ").trim();
Object.entries(TERMS).flatMap(([token, phrases]) => phrases.map((p) => [clean(p), token])).sort((a, b) => b[0].length - a[0].length);
//#endregion
//#region lib/amazon-id.mjs
function amazonAsin(value) {
	const text = String(value || "").trim();
	if (/^[A-Z0-9]{10}$/i.test(text)) return text.toUpperCase();
	try {
		const u = new URL(text);
		if (u.protocol !== "https:" || !["www.amazon.sa", "amazon.sa"].includes(u.hostname) || u.port || u.username || u.password) return null;
		return u.pathname.match(/\/(?:dp|gp\/product)\/([A-Z0-9]{10})(?:\/|$)/i)?.[1].toUpperCase() || null;
	} catch {
		return null;
	}
}
//#endregion
//#region lib/market.mjs
var now = () => Date.now();
var iso = (value) => new Date(value).toISOString();
function normalize(value) {
	return String(value ?? "").toLowerCase().replace(/[٠-٩]/g, (c) => "٠١٢٣٤٥٦٧٨٩".indexOf(c)).replace(/[۰-۹]/g, (c) => "۰۱۲۳۴۵۶۷۸۹".indexOf(c)).replace(/٫/g, ".").replace(/[أإآ]/g, "ا").replace(/ة/g, "ه").replace(/[\u064B-\u065Fـ]/g, "").replace(/\s+/g, " ").trim();
}
var measurement = readQuantity;
function validBarcode(value) {
	if (!/^(?:\d{8}|\d{12,14})$/.test(value ?? "")) return false;
	let total = 0, weight = 3;
	for (let i = value.length - 2; i >= 0; i--, weight = 4 - weight) total += Number(value[i]) * weight;
	return (10 - total % 10) % 10 === Number(value.at(-1));
}
//#endregion
//#region lib/retailers.mjs
var RETAILERS = Object.fromEntries(Object.entries(STORES).filter(([code, s]) => s.live && code !== "danube"));
var WORDS = {
	"نوتيلا": "nutella",
	"بيبسي": "pepsi",
	"المراعي": "almarai",
	"السعوديه": "saudia",
	"نادك": "nadec",
	"الصافي": "alsafi",
	"حليب": "milk",
	"لبن": "laban",
	"زبادي": "yogurt",
	"عصير": "juice",
	"ارز": "rice",
	"رز": "rice",
	"سكر": "sugar",
	"زيت": "oil",
	"شاي": "tea",
	"قهوه": "coffee",
	"نسكافيه": "nescafe",
	"نيدو": "nido",
	"حفاضات": "diapers",
	"بامبرز": "pampers",
	"اوريو": "oreo",
	"لوزين": "lusine",
	"جبن": "cheese",
	"توست": "toast",
	"بيض": "eggs",
	"عافيه": "afia",
	"الشعلان": "alshalan",
	"الاسره": "al osra",
	"ابو كاس": "abu kass",
	"بسمتي": "basmati",
	"كامل الدسم": "full fat",
	"قليل الدسم": "low fat",
	"خالي الدسم": "skimmed",
	"طازج": "fresh",
	"شوكولاته": "chocolate",
	"شوكولاتا": "chocolate",
	"شوكولا": "chocolate",
	"بسكويت": "biscuits",
	"دايت": "diet",
	"زيرو": "zero",
	"خالي من السكر": "sugar free",
	"كولا": "cola",
	"علبه": "can",
	"زجاج": "glass",
	"ماء": "water",
	"مياه": "water",
	"هنا": "hana",
	"نوفا": "nova",
	"صفا": "safa",
	"دجاج": "chicken"
};
function englishQuery(query, products = []) {
	let s = " " + normalize(query) + " ";
	const aliases = /* @__PURE__ */ new Map();
	for (const p of products) if (p.brand_ar && p.brand_en && /[a-z]/i.test(p.brand_en)) {
		const ar = normalize(p.brand_ar), en = normalize(p.brand_en);
		if (!aliases.has(ar)) aliases.set(ar, /* @__PURE__ */ new Set());
		aliases.get(ar).add(en);
	}
	for (const [ar, names] of [...aliases].sort((a, b) => b[0].length - a[0].length)) if (names.size === 1) s = s.replaceAll(" " + ar + " ", " " + [...names][0] + " ");
	for (const [a, b] of Object.entries(WORDS).sort((a, b) => b[0].length - a[0].length)) s = s.replaceAll(" " + a + " ", " " + b + " ");
	return s.trim();
}
function url(value, origin) {
	try {
		const u = new URL(value, origin);
		return u.protocol === "https:" && !u.username && !u.password ? u.href : null;
	} catch {
		return null;
	}
}
function price(value) {
	if (value === null || value === "" || value === void 0) return null;
	const n = Math.round(Number(value) * 100);
	return Number.isSafeInteger(n) && n > 0 && n <= 1e7 ? n : null;
}
function product(code, id, name, brand, sizeText, barcode, image, link, value, original, stock, at, branch) {
	const amount = price(value);
	if (!id || !name || !amount || !link) return null;
	const size = measurement(sizeText), pack = size.pack || 1, prior = price(original);
	const nameAr = brand && !normalize(name).includes(normalize(brand)) ? `${brand} ${name}` : name;
	return {
		source_id: `${code}:${id}`,
		name_ar: nameAr,
		name_en: nameAr,
		brand_ar: brand || null,
		category: "بقالة",
		gtin_barcode: validBarcode(String(barcode || "").trim()) ? String(barcode).trim() : null,
		...quantityFields(size),
		image_url: image ? url(image, RETAILERS[code].origin) : null,
		offers: [{
			store_code: code,
			store_name_ar: RETAILERS[code].name,
			branch_name_ar: branch || "كتالوج المتجر الإلكتروني؛ فرع المدينة والتوصيل غير مؤكدين",
			price_halalas: amount,
			price_sar: amount / 100,
			original_price_sar: prior > amount ? prior / 100 : null,
			is_on_sale: prior > amount,
			is_in_stock: stock === true,
			stock_known: typeof stock === "boolean",
			price_verified: true,
			product_url: link,
			source_url: link,
			last_verified_at: iso(at),
			delivery_fee_sar: null,
			total_landed_sar: null,
			total_status: "REQUIRES_STORE_CONFIRMATION",
			total_status_text: "رسوم التوصيل والخدمة تُؤكّد لدى المتجر",
			is_cheapest_product: false,
			is_cheapest_total: false,
			unit_price_per_100g_sar: size.amount && size.unit !== "count" ? amount / (size.amount * pack) : null
		}]
	};
}
async function publicPage(target, fetcher, signal) {
	const origin = new URL(target).origin;
	for (let hop = 0; hop < 3; hop++) {
		const r = await fetcher(target, {
			headers: { Accept: "text/html" },
			signal,
			redirect: "manual"
		});
		if (r.status >= 300 && r.status < 400) {
			const next = new URL(r.headers.get("location") || "", target);
			if (next.origin !== origin) throw Error("cross_origin_redirect");
			target = next.href;
			continue;
		}
		if (!r.ok) throw Error("retailer_http_" + r.status);
		const body = await r.text();
		if (body.length > 4e6) throw Error("catalog_too_large");
		return body;
	}
	throw Error("redirect_limit");
}
//#endregion
//#region lib/public-html.mjs
function decodeHtml(value = "") {
	return String(value).replace(/&(#x[0-9a-f]+|#\d+|quot|apos|amp|lt|gt|nbsp);/gi, (_, e) => {
		if (e[0] === "#") {
			const n = e[1].toLowerCase() === "x" ? parseInt(e.slice(2), 16) : Number(e.slice(1));
			return n > 0 && n <= 1114111 ? String.fromCodePoint(n) : "";
		}
		return {
			quot: "\"",
			apos: "'",
			amp: "&",
			lt: "<",
			gt: ">",
			nbsp: " "
		}[e.toLowerCase()];
	});
}
var VOID = new Set("area base br col embed hr img input link meta param source track wbr".split(" "));
function readHtml(input) {
	if (input.length > 4e6) throw Error("catalog_too_large");
	const root = {
		tag: "root",
		attrs: {},
		children: []
	}, stack = [root], nodes = [];
	const clean = input.replace(/<!--[\s\S]*?-->|<(script|style)\b[^>]*>[\s\S]*?<\/\1\s*>/gi, "");
	for (const m of clean.matchAll(/<\/?[a-z][a-z0-9:-]*\b(?:"[^"]*"|'[^']*'|[^'">])*\s*\/?>|[^<]+|</gi)) {
		const s = m[0];
		if (s.startsWith("</")) {
			const tag = s.match(/^<\/([\w:-]+)/)[1].toLowerCase();
			const i = stack.findLastIndex((n) => n.tag === tag);
			if (i > 0) stack.length = i;
		} else if (/^<[a-z]/i.test(s)) {
			const tag = s.match(/^<([\w:-]+)/)[1].toLowerCase();
			const node = {
				tag,
				attrs: Object.fromEntries([...s.matchAll(/([\w:-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/g)].map((a) => [a[1].toLowerCase(), decodeHtml(a[2] ?? a[3] ?? a[4])])),
				children: []
			};
			stack.at(-1).children.push(node);
			nodes.push(node);
			if (nodes.length > 1e5) throw Error("catalog_too_large");
			if (!VOID.has(tag) && !s.endsWith("/>")) {
				if (stack.length > 128) throw Error("catalog_format_changed");
				stack.push(node);
			}
		} else stack.at(-1).children.push(decodeHtml(s));
	}
	return {
		root,
		nodes,
		id: (value) => nodes.find((n) => n.attrs.id === value)
	};
}
function descendants(node, predicate) {
	const result = [], stack = node ? [node] : [];
	while (stack.length) {
		const n = stack.pop();
		if (typeof n === "string") continue;
		if (predicate(n)) result.push(n);
		stack.push(...n.children.toReversed());
	}
	return result;
}
var hasClass = (node, name) => (node?.attrs.class || "").split(/\s+/).includes(name);
var htmlText = (node) => !node ? "" : typeof node === "string" ? node : node.children.map(htmlText).join(" ").replace(/\s+/g, " ").trim();
//#endregion
//#region lib/amazon-catalog.mjs
var AMAZON_CATALOG = [
	["B00IDIX2EW", "Nutella نوتيلا"],
	["B07QW9RKZJ", "Nutella نوتيلا بسكويت biscuits"],
	["B00LOZWYPO", "Nutella نوتيلا"],
	["B0005Z6ZK4", "Nutella نوتيلا"],
	["B079WT67HL", "Nutella نوتيلا"],
	["B08DJN5L3Z", "Pepsi بيبسي كولا cola"],
	["B08DJLQY7M", "Pepsi بيبسي كولا cola"],
	["B088FJ811M", "Pepsi بيبسي zero زيرو"],
	["B08DJMKK17", "Pepsi بيبسي diet دايت"],
	["B07PKD7L5P", "Pampers بامبرز diapers حفاضات"],
	["B0F6273LRY", "Pampers بامبرز diapers حفاضات"],
	["B0F9FH2T9D", "Pampers بامبرز diapers حفاضات"],
	["B0DZJ4BT19", "Pampers بامبرز wipes مناديل"],
	["B07J9TGT78", "Nescafe نسكافيه coffee قهوة classic كلاسيك"],
	["B077SH99VN", "Nescafe نسكافيه coffee قهوة gold جولد"],
	["B007ZFSIBQ", "Nescafe نسكافيه coffee قهوة red mug ريد مج"]
].map(([asin, keywords]) => ({
	asin,
	keywords
}));
//#endregion
//#region lib/amazon-public.mjs
var ORIGIN = "https://www.amazon.sa";
var LIMIT = 6;
var blocked = (error) => /retailer_http_(?:401|403|429)|retailer_challenge/.test(error?.message || "");
function challenge(html) {
	if (/(?:action|src)=["'][^"']*(?:validateCaptcha|captcha\/)|<title>\s*(?:Robot Check|Amazon CAPTCHA)/i.test(html)) throw Error("retailer_challenge");
}
function amount(node) {
	const priceNodes = descendants(node, (n) => hasClass(n, "a-price") && !hasClass(n, "a-text-price"));
	const values = [];
	for (const price of priceNodes) {
		const off = descendants(price, (n) => hasClass(n, "a-offscreen"))[0];
		const text = normalize(htmlText(off)).replace(/[\u200e\u200f\u061c]/g, "");
		if (!/(?:ريال|ر\.س|\bSAR\b)/i.test(text) || /(?:AED|USD|درهم|\$)/i.test(text)) continue;
		const numbers = text.match(/\d[\d,]*(?:\.\d{1,2})?/g) || [];
		if (numbers.length !== 1) continue;
		const value = Number(numbers[0].replaceAll(",", ""));
		if (Number.isFinite(value) && value > 0 && value <= 1e5) values.push(value);
	}
	const unique = [...new Set(values)];
	return unique.length === 1 ? unique[0] : null;
}
function parseAmazonProduct(html, asin, at = now()) {
	if (amazonAsin(asin) !== asin) throw Error("product_identity_mismatch");
	challenge(html);
	const doc = readHtml(html);
	if (doc.id("ASIN")?.attrs.value !== asin) throw Error("product_identity_mismatch");
	const title = htmlText(doc.id("productTitle"));
	if (!title || title.length > 700) return [];
	const category = htmlText(doc.id("wayfinding-breadcrumbs_feature_div"));
	if (!/(?:السوبر ماركت|سوبر ماركت|البقالة|grocery|health|personal care|beauty|baby|الصحة|العناية|الجمال|الطفل|الأطفال)/i.test(category)) return [];
	const buybox = doc.id("desktop_qualifiedBuyBox") || doc.id("buybox");
	if (/Amazon\s*Now|أمازون\s*ناو|امازون\s*ناو/i.test(htmlText(buybox))) return [];
	let value = null, kind = "listed";
	for (const id of [
		"corePriceDisplay_desktop_feature_div",
		"corePrice_feature_div",
		"corePrice_desktop"
	]) {
		const block = doc.id(id);
		if (!block) continue;
		value = amount(descendants(block, (n) => hasClass(n, "priceToPay"))[0] || block);
		if (value !== null) break;
	}
	if (value === null) {
		const ingress = doc.id("aod-ingress-link");
		try {
			const link = new URL(ingress?.attrs.href || "", ORIGIN);
			const offerPath = "/gp/offer-listing/" + asin;
			if (link.origin === ORIGIN && (link.pathname === offerPath || link.pathname.startsWith(offerPath + "/")) && link.searchParams.get("condition") === "NEW" && /(?:خيارات\s+من|عروض\s+من|(?:options|offers|new)\s+from)/i.test(htmlText(ingress))) {
				value = amount(ingress);
				kind = "starting_from";
			}
		} catch {}
	}
	if (value === null) return [];
	const brand = htmlText(doc.id("bylineInfo")).replace(/^(?:العلامة التجارية[:：]?|Brand[:：]?|Visit the)\s*/i, "").replace(/\s*Store$/i, "").trim();
	const img = doc.id("landingImage")?.attrs;
	const image = img?.["data-old-hires"] || img?.src;
	const source = ORIGIN + "/dp/" + asin;
	const p = product("amazon", asin, title, brand || null, title, null, image, ORIGIN, value, null, void 0, at, "وجهة المقارنة المفترضة: المدينة المنورة؛ السعر قبل التوصيل وقد يختلف عند اختيار العنوان");
	if (!p) return [];
	p.category_names = [category];
	p.retailer_product_id = asin;
	p.provider_product_id = asin;
	p.provider_url = source;
	p.provider = "amazon.sa";
	p.offers = p.offers.map((o) => ({
		...o,
		source_url: source,
		price_source_type: "amazon_public_page",
		price_source_name: "أمازون السعودية",
		price_kind: kind,
		price_confidence: "indicative",
		price_expires_at: iso(at + 36e5),
		supports_alerts: false,
		delivery_city: "المدينة المنورة",
		delivery_location_verified: false,
		promo_conditions: kind === "starting_from" ? "ابتداءً من أقل عرض جديد ظاهر في صفحة أمازون" : "السعر الظاهر في صفحة أمازون",
		total_status_text: "سعر استرشادي قبل الرسوم؛ التوصيل للمدينة المنورة يُؤكد لدى أمازون"
	}));
	return [p];
}
function discoverAmazonSearch(html) {
	challenge(html);
	const doc = readHtml(html), ids = [];
	for (const n of doc.nodes) if (n.attrs["data-component-type"] === "s-search-result" && amazonAsin(n.attrs["data-asin"])) ids.push(n.attrs["data-asin"].toUpperCase());
	return [...new Set(ids)].slice(0, LIMIT);
}
async function knownAsins(query, db) {
	const words = normalize(englishQuery(query)).split(/\s+/).filter(Boolean);
	let rows = AMAZON_CATALOG;
	if (db) rows = [...((await db.prepare("SELECT value FROM state WHERE key LIKE 'amazon-catalog:%' AND expires>? ORDER BY expires DESC LIMIT 500").bind(now()).all()).results || []).flatMap((r) => {
		try {
			return [JSON.parse(r.value)];
		} catch {
			return [];
		}
	}), ...rows];
	return [...new Set(rows.filter((r) => words.every((w) => normalize(englishQuery(r.keywords)).includes(w))).map((r) => r.asin).filter((x) => amazonAsin(x) === x))].slice(0, LIMIT);
}
async function details(ids, fetcher, signal, db) {
	const results = await Promise.allSettled(ids.slice(0, LIMIT).map(async (asin) => {
		const ps = parseAmazonProduct(await publicPage(ORIGIN + "/dp/" + asin, fetcher, signal), asin);
		if (db && ps.length) {
			const keywords = ps[0].name_ar + " " + (ps[0].brand_ar || "");
			await db.prepare("INSERT INTO state(key,value,expires) VALUES(?,?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value,expires=excluded.expires").bind("amazon-catalog:" + asin, JSON.stringify({
				asin,
				keywords
			}), now() + 180 * 864e5).run();
		}
		return ps;
	}));
	const denied = results.find((r) => r.status === "rejected" && blocked(r.reason));
	if (denied) throw denied.reason;
	if (ids.length && !results.some((r) => r.status === "fulfilled")) throw results[0].reason;
	return results.flatMap((r) => r.status === "fulfilled" ? r.value : []);
}
async function searchAmazonPublic(query, fetcher, db) {
	const keyword = englishQuery(query), asin = amazonAsin(query);
	return collectPublicPrices(db, asin || keyword, async () => {
		const signal = AbortSignal.timeout(18e3);
		if (asin) return details([asin], fetcher, signal, db);
		const known = await knownAsins(keyword, db);
		if (known.length) return details(known, fetcher, signal, db);
		return details(discoverAmazonSearch(await publicPage(ORIGIN + "/s?k=" + encodeURIComponent(keyword), fetcher, signal)), fetcher, signal, db);
	}, {
		provider: "amazon.sa",
		namespace: "amazon-direct-v1"
	});
}
async function refreshAmazonPublic(refs, fetcher) {
	return details([...new Set(refs.filter((r) => r.provider === "amazon.sa" && r.source_id === "amazon:" + r.retailer_product_id).map((r) => r.retailer_product_id).filter((x) => amazonAsin(x) === x))], fetcher, AbortSignal.timeout(18e3));
}
async function diagnoseAmazonPublic(value, fetcher, mode = "product") {
	const asin = amazonAsin(value);
	if (!asin) throw Error("product_identity_mismatch");
	const html = await publicPage(ORIGIN + (mode === "offers" ? "/gp/offer-listing/" + asin + "/ref=dp_olp_unknown_mbc" : "/dp/" + asin), fetcher, AbortSignal.timeout(18e3));
	challenge(html);
	const doc = readHtml(html), text = (id) => htmlText(doc.id(id)).slice(0, 500);
	return {
		asin,
		bytes: html.length,
		identity: doc.id("ASIN")?.attrs.value || null,
		title: text("productTitle"),
		category: text("wayfinding-breadcrumbs_feature_div"),
		availability: text("availability"),
		buybox: text("desktop_qualifiedBuyBox") || text("buybox"),
		price_blocks: Object.fromEntries([
			"corePriceDisplay_desktop_feature_div",
			"corePrice_feature_div",
			"corePrice_desktop",
			"aod-ingress-link",
			"olpOfferList",
			"aod-offer-list"
		].map((id) => [id, text(id)])),
		displayed_price_samples: doc.nodes.filter((n) => hasClass(n, "a-offscreen")).slice(0, 12).map((n) => htmlText(n).slice(0, 100)),
		parsed_offers: doc.id("ASIN")?.attrs.value === asin ? parseAmazonProduct(html, asin).length : 0
	};
}
//#endregion
export { diagnoseAmazonPublic, discoverAmazonSearch, parseAmazonProduct, refreshAmazonPublic, searchAmazonPublic };
