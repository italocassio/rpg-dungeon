// Gera as texturas PBR do jogo (sem dependências): node tools/bake_textures.mjs
// Todas são contínuas (tileable). Saída em assets/textures/.
import { deflateSync, crc32 } from "node:zlib";
import { writeFileSync, mkdirSync } from "node:fs";

const OUT = new URL("../assets/textures/", import.meta.url).pathname;
mkdirSync(OUT, { recursive: true });

// ---------- utilidades ----------
const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
const lerp = (a, b, t) => a + (b - a) * t;
const smooth = (a, b, x) => {
	const t = clamp((x - a) / (b - a));
	return t * t * (3 - 2 * t);
};
const frac = (x) => x - Math.floor(x);
const mod = (a, n) => ((a % n) + n) % n;

function rngFrom(seed) {
	let s = seed >>> 0 || 1;
	return () => {
		s ^= s << 13; s >>>= 0;
		s ^= s >>> 17;
		s ^= s << 5; s >>>= 0;
		return s / 4294967296;
	};
}

function writePng(name, w, h, rgba) {
	const stride = w * 4 + 1;
	const raw = Buffer.alloc(stride * h);
	for (let y = 0; y < h; y++) {
		raw[y * stride] = 0;
		Buffer.from(rgba.buffer, y * w * 4, w * 4).copy(raw, y * stride + 1);
	}
	const chunk = (type, data) => {
		const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
		const body = Buffer.concat([Buffer.from(type), data]);
		const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(body));
		return Buffer.concat([len, body, crc]);
	};
	const ihdr = Buffer.alloc(13);
	ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
	ihdr[8] = 8; ihdr[9] = 6;
	const png = Buffer.concat([
		Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
		chunk("IHDR", ihdr), chunk("IDAT", deflateSync(raw, { level: 9 })), chunk("IEND", Buffer.alloc(0)),
	]);
	writeFileSync(OUT + name, png);
	console.log(name, (png.length / 1024 / 1024).toFixed(2) + " MB");
}

class Perlin {
	constructor(seed) {
		const r = rngFrom(seed);
		this.perm = new Uint8Array(512);
		const p = [...Array(256).keys()];
		for (let i = 255; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [p[i], p[j]] = [p[j], p[i]]; }
		for (let i = 0; i < 512; i++) this.perm[i] = p[i & 255];
		this.gx = new Float32Array(256); this.gy = new Float32Array(256);
		for (let i = 0; i < 256; i++) { const a = r() * Math.PI * 2; this.gx[i] = Math.cos(a); this.gy[i] = Math.sin(a); }
	}
	// x, y em células; px, py = período inteiro
	noise(x, y, px, py) {
		const xi = Math.floor(x), yi = Math.floor(y);
		const xf = x - xi, yf = y - yi;
		const u = xf * xf * xf * (xf * (xf * 6 - 15) + 10);
		const v = yf * yf * yf * (yf * (yf * 6 - 15) + 10);
		const h = (ix, iy) => this.perm[(this.perm[mod(ix, px) & 255] + mod(iy, py)) & 255];
		const g = (ix, iy, dx, dy) => { const k = h(ix, iy); return this.gx[k] * dx + this.gy[k] * dy; };
		return lerp(
			lerp(g(xi, yi, xf, yf), g(xi + 1, yi, xf - 1, yf), u),
			lerp(g(xi, yi + 1, xf, yf - 1), g(xi + 1, yi + 1, xf - 1, yf - 1), u), v) * 1.5;
	}
	// u, v em [0,1): fBm periódico, retorno aproximado em [-1, 1]
	fbm(u, v, period, oct = 4, gain = 0.5) {
		let a = 1, s = 0, n = 0, p = period;
		for (let i = 0; i < oct; i++) {
			s += a * this.noise(u * p, v * p, p, p);
			n += a; a *= gain; p *= 2;
		}
		return s / n;
	}
}

// Voronoi periódico: retorna [F1, F2]
function makeVoronoi(seed, n) {
	const r = rngFrom(seed);
	const px = new Float32Array(n * n), py = new Float32Array(n * n);
	for (let i = 0; i < n * n; i++) { px[i] = r(); py[i] = r(); }
	return (u, v) => {
		const x = u * n, y = v * n, xi = Math.floor(x), yi = Math.floor(y);
		let f1 = 9, f2 = 9;
		for (let j = -2; j <= 2; j++) for (let i = -2; i <= 2; i++) {
			const cx = xi + i, cy = yi + j, id = mod(cx, n) + mod(cy, n) * n;
			const dx = cx + px[id] - x, dy = cy + py[id] - y;
			const d = Math.sqrt(dx * dx + dy * dy);
			if (d < f1) { f2 = f1; f1 = d; } else if (d < f2) f2 = d;
		}
		return [f1, f2];
	};
}

// Normal map (convenção OpenGL/Godot, Y+) a partir de um campo de altura contínuo.
function normalsFrom(h, W, H, strength) {
	const out = new Uint8Array(W * H * 4);
	for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
		const l = h[mod(x - 1, W) + y * W], r = h[mod(x + 1, W) + y * W];
		const d = h[x + mod(y - 1, H) * W], u = h[x + mod(y + 1, H) * W];
		let nx = -(r - l) * strength, ny = (u - d) * strength, nz = 1;
		const m = Math.hypot(nx, ny, nz); nx /= m; ny /= m; nz /= m;
		const i = (x + y * W) * 4;
		out[i] = (nx * .5 + .5) * 255; out[i + 1] = (ny * .5 + .5) * 255; out[i + 2] = (nz * .5 + .5) * 255; out[i + 3] = 255;
	}
	return out;
}

function savePbr(name, W, H, albedoFn, h, strength, roughFn) {
	const a = new Uint8Array(W * H * 4), orm = new Uint8Array(W * H * 4);
	// AO aproximado: diferença para a média local da altura (blur em cruz larga)
	const R = Math.max(4, Math.round(W / 96));
	for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
		const i = x + y * W;
		const [r, g, b] = albedoFn(x, y, i);
		a[i * 4] = clamp(r) * 255; a[i * 4 + 1] = clamp(g) * 255; a[i * 4 + 2] = clamp(b) * 255; a[i * 4 + 3] = 255;
		let avg = 0;
		for (const [dx, dy] of [[R, 0], [-R, 0], [0, R], [0, -R], [R, R], [-R, R], [R, -R], [-R, -R]]) avg += h[mod(x + dx, W) + mod(y + dy, H) * W];
		avg /= 8;
		const ao = clamp(1 - Math.max(0, avg - h[i]) * 3.2, 0.15, 1);
		orm[i * 4] = ao * 255; orm[i * 4 + 1] = clamp(roughFn(x, y, i)) * 255; orm[i * 4 + 2] = clamp(h[i]) * 255; orm[i * 4 + 3] = 255;
	}
	writePng(`${name}_albedo.png`, W, H, a);
	writePng(`${name}_normal.png`, W, H, normalsFrom(h, W, H, strength));
	writePng(`${name}_orm.png`, W, H, orm);
}

// Campo de blocos em fiadas irregulares; devolve altura, tom por bloco e máscara de junta.
function blockField(W, H, opt) {
	const { rows, minCols, maxCols, bevel, corner, warp, seed, rowSkew = 0 } = opt;
	const n1 = new Perlin(seed), n2 = new Perlin(seed + 11), n3 = new Perlin(seed + 23), n4 = new Perlin(seed + 37);
	const r = rngFrom(seed * 7 + 3);
	const layout = [];
	for (let i = 0; i < rows; i++) {
		const cols = minCols + Math.floor(r() * (maxCols - minCols + 1));
		const w = []; let s = 0;
		for (let c = 0; c < cols; c++) { const x = 0.6 + r() * 0.8; w.push(x); s += x; }
		let acc = 0; const b = [0];
		for (const x of w) { acc += x / s; b.push(acc); }
		layout.push({ cols, b, off: r(), tone: w.map(() => r()), lift: w.map(() => r()) });
	}
	const height = new Float32Array(W * H), tone = new Float32Array(W * H), joint = new Float32Array(W * H);
	for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
		const u0 = x / W, v0 = y / H;
		const wu = warp * n1.fbm(u0, v0, 3, 3), wv = warp * n2.fbm(u0, v0, 3, 3);
		const v = frac(v0 + wv + rowSkew * Math.sin(u0 * Math.PI * 2) * 0.01);
		const ri = Math.floor(v * rows) % rows, ry = v * rows - Math.floor(v * rows);
		const row = layout[ri];
		const u = frac(u0 + wu + row.off);
		let c = 0;
		while (c < row.cols - 1 && u >= row.b[c + 1]) c++;
		const b0 = row.b[c], b1 = row.b[c + 1];
		const aspect = rows * (W / H); // largura de 1 fiada em unidades de altura
		const hw = (b1 - b0) * aspect * 0.5, hh = 0.5;
		const px = Math.abs(u - (b0 + b1) * 0.5) * aspect, py = Math.abs(ry - 0.5);
		const qx = px - hw + corner, qy = py - hh + corner;
		const sd = Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) + Math.min(Math.max(qx, qy), 0) - corner;
		const inside = clamp(-sd / bevel);
		const pillow = 1 - (1 - inside) * (1 - inside);
		const detail = n3.fbm(u0, v0, 9, 5, 0.55), big = n4.fbm(u0, v0, 4, 3);
		height[x + y * W] = clamp(0.06 + pillow * (0.62 + row.lift[c] * 0.14) + pillow * (detail * 0.16 + big * 0.16));
		tone[x + y * W] = row.tone[c];
		joint[x + y * W] = 1 - pillow;
	}
	return { height, tone, joint, n3, n4 };
}

// ---------- pedra das paredes ----------
function bakeWall() {
	const S = 1024;
	const f = blockField(S, S, { rows: 5, minCols: 2, maxCols: 3, bevel: 0.34, corner: 0.22, warp: 0.022, seed: 42, rowSkew: 1 });
	const crack = makeVoronoi(901, 14);
	for (let i = 0; i < S * S; i++) {
		const x = i % S, y = (i - x) / S;
		const [a, b] = crack(x / S, y / S);
		f.height[i] = clamp(f.height[i] - (1 - smooth(0, 0.035, b - a)) * 0.14 * (1 - f.joint[i]));
	}
	const alb = (x, y, i) => {
		const u = x / S, v = y / S;
		const n = f.n3.fbm(u, v, 12, 5, 0.6), m = f.n4.fbm(u, v, 5, 3);
		const t = f.tone[i], h = f.height[i];
		const base = 0.20 + t * 0.09 + n * 0.10 + m * 0.07;
		const shade = lerp(0.42, 1.08, smooth(0.05, 0.62, h));
		const lum = base * shade;
		const lichen = smooth(0.15, 0.5, m) * 0.05;
		return [lum * 0.94 - lichen * 0.3, lum * 1.0, lum * 1.17 + lichen * 0.2];
	};
	savePbr("stone_wall", S, S, alb, f.height, 7.5, (x, y, i) => {
		const n = f.n3.fbm(x / S, y / S, 20, 3);
		return 0.62 + n * 0.22 + f.joint[i] * 0.2;
	});
}

// ---------- lajes do piso ----------
function bakeFloor() {
	const S = 1024;
	const f = blockField(S, S, { rows: 4, minCols: 3, maxCols: 4, bevel: 0.1, corner: 0.05, warp: 0.006, seed: 77 });
	const crack = makeVoronoi(313, 9);
	for (let i = 0; i < S * S; i++) {
		const x = i % S, y = (i - x) / S;
		const [a, b] = crack(x / S, y / S);
		f.height[i] = clamp(f.height[i] - (1 - smooth(0.0, 0.022, b - a)) * 0.22);
	}
	const alb = (x, y, i) => {
		const u = x / S, v = y / S, h = f.height[i];
		const n = f.n3.fbm(u, v, 10, 5, 0.6);
		const lum = (0.19 + f.tone[i] * 0.07 + n * 0.08) * lerp(0.45, 1.05, smooth(0.05, 0.6, h));
		return [lum * 0.92, lum * 0.98, lum * 1.12];
	};
	savePbr("stone_floor", S, S, alb, f.height, 5, (x, y, i) => 0.5 + f.n3.fbm(x / S, y / S, 16, 3) * 0.25 + f.joint[i] * 0.25);
}

// ---------- neve ----------
function bakeSnow() {
	const S = 512, n = new Perlin(5), m = new Perlin(6);
	const h = new Float32Array(S * S);
	for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) {
		const u = x / S, v = y / S;
		const ridges = 1 - Math.abs(n.fbm(u, v, 4, 4));
		h[x + y * S] = clamp(0.5 + m.fbm(u, v, 6, 5, 0.55) * 0.45 + (ridges - 0.7) * 0.5);
	}
	const sparkle = rngFrom(99);
	const spark = new Float32Array(S * S).map(() => (sparkle() > 0.9975 ? 1 : 0));
	savePbr("snow", S, S, (x, y, i) => {
		const t = 0.8 + h[i] * 0.2 + spark[i] * 0.15;
		return [t * 0.86, t * 0.93, t * 1.02];
	}, h, 2.2, (x, y, i) => 0.62 - spark[i] * 0.4);
}

// ---------- gelo ----------
function bakeIce() {
	const S = 512, n = new Perlin(15), vo = makeVoronoi(77, 7), vo2 = makeVoronoi(78, 15);
	const h = new Float32Array(S * S), cracks = new Float32Array(S * S);
	for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) {
		const u = x / S, v = y / S;
		const [a, b] = vo(u, v), [c, d] = vo2(u, v);
		const line = Math.max(1 - smooth(0, 0.03, b - a), (1 - smooth(0, 0.035, d - c)) * 0.45);
		cracks[x + y * S] = line;
		h[x + y * S] = clamp(0.6 + n.fbm(u, v, 5, 4) * 0.25 - line * 0.35);
	}
	savePbr("ice", S, S, (x, y, i) => {
		const c = cracks[i], t = h[i];
		return [0.32 + t * 0.12 + c * 0.45, 0.52 + t * 0.14 + c * 0.38, 0.72 + t * 0.12 + c * 0.25];
	}, h, 2.6, (x, y, i) => 0.1 + cracks[i] * 0.45);
}

// ---------- madeira ----------
function bakeWood() {
	const S = 512, n = new Perlin(25), m = new Perlin(26);
	const planks = 5, h = new Float32Array(S * S), tone = new Float32Array(S * S);
	const r = rngFrom(4); const pt = [...Array(planks)].map(() => r());
	for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) {
		const u = x / S, v = y / S, p = Math.floor(u * planks), fx = u * planks - p;
		const edge = Math.min(fx, 1 - fx);
		const grain = n.fbm(frac(u + pt[p]), v, 2, 3) * 0;
		const lines = Math.sin((u * 64 + m.fbm(u, v, 3, 3) * 12 + pt[p] * 20) * Math.PI);
		const fine = m.fbm(u, v, 18, 3);
		tone[x + y * S] = pt[p];
		h[x + y * S] = clamp(smooth(0, 0.07, edge) * (0.68 + lines * 0.08 + fine * 0.14 + grain));
	}
	savePbr("wood", S, S, (x, y, i) => {
		const t = 0.5 + h[i] * 0.55 + tone[i] * 0.2;
		return [0.34 * t, 0.21 * t, 0.12 * t];
	}, h, 3.2, () => 0.72);
}

// ---------- metal martelado ----------
function bakeMetal() {
	const S = 512, n = new Perlin(35), m = new Perlin(36), vo = makeVoronoi(55, 18);
	const h = new Float32Array(S * S), rust = new Float32Array(S * S);
	for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) {
		const u = x / S, v = y / S;
		const [a] = vo(u, v);
		h[x + y * S] = clamp(0.5 + (0.4 - a) * 0.25 + n.fbm(u, v, 22, 3) * 0.1);
		rust[x + y * S] = smooth(0.12, 0.42, m.fbm(u, v, 6, 5));
	}
	savePbr("metal", S, S, (x, y, i) => {
		const t = 0.52 + h[i] * 0.3, c = rust[i];
		return [lerp(t, 0.36, c), lerp(t, 0.24, c), lerp(t, 0.18, c)];
	}, h, 1.6, (x, y, i) => 0.3 + rust[i] * 0.5);
}

// ---------- ruído tileável genérico para shaders ----------
function bakeNoise() {
	const S = 256, n = new Perlin(45), m = new Perlin(46);
	const a = new Uint8Array(S * S * 4);
	for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) {
		const u = x / S, v = y / S, i = (x + y * S) * 4;
		a[i] = clamp(0.5 + n.fbm(u, v, 3, 5, 0.55) * 0.9) * 255;
		a[i + 1] = clamp(0.5 + m.fbm(u, v, 8, 4, 0.55) * 0.9) * 255;
		a[i + 2] = clamp(0.5 + n.fbm(u, v, 16, 3) * 0.9) * 255;
		a[i + 3] = 255;
	}
	writePng("noise.png", S, S, a);
}

// ---------- sprites de partículas ----------
function bakeSprites() {
	const S = 128;
	const put = (name, fn) => {
		const a = new Uint8Array(S * S * 4);
		for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) {
			const px = (x + 0.5) / S * 2 - 1, py = (y + 0.5) / S * 2 - 1, i = (x + y * S) * 4;
			a[i] = a[i + 1] = a[i + 2] = 255;
			a[i + 3] = clamp(fn(px, py)) * 255;
		}
		writePng(name, S, S, a);
	};
	put("fx_soft.png", (x, y) => Math.pow(clamp(1 - Math.hypot(x, y)), 2));
	put("fx_spark.png", (x, y) => {
		const d = Math.hypot(x, y);
		return Math.pow(clamp(1 - d), 3) + clamp(1 - Math.abs(x) * 26) * clamp(1 - Math.abs(y)) * 0.6 + clamp(1 - Math.abs(y) * 26) * clamp(1 - Math.abs(x)) * 0.6;
	});
	put("fx_flake.png", (x, y) => {
		const d = Math.hypot(x, y), a = Math.atan2(y, x);
		const sector = Math.abs(mod(a + Math.PI / 6, Math.PI / 3) - Math.PI / 6);
		const arm = Math.abs(Math.sin(sector)) * d;
		const branch = Math.abs(Math.abs(d * Math.cos(sector) - 0.55) - Math.abs(arm) * 0.9);
		const core = clamp(1 - arm * 16) * clamp(1 - d * 1.15);
		const side = clamp(1 - branch * 14) * clamp(1 - d * 1.15);
		return clamp(Math.max(core, side) + Math.pow(clamp(1 - d * 3), 2));
	});
	const smokeN = new Perlin(65);
	put("fx_smoke.png", (x, y) => {
		const d = Math.hypot(x, y);
		return clamp((1 - d) * 1.5 + smokeN.fbm(frac((x + 1) / 2), frac((y + 1) / 2), 4, 4) * 1.2) * smooth(1, 0.6, d);
	});
}

bakeWall(); bakeFloor(); bakeSnow(); bakeIce(); bakeWood(); bakeMetal(); bakeNoise(); bakeSprites();
