# DeelMarkt — Kapsamlı Fizibilite, Rekabet Analizi ve Strateji Raporu
### + Tier-1 Production-Grade Architecture Audit (v3.0)

**Hollanda Dijital Pazar Platformu | Marktplaats.nl'ye Rekabetçi Alternatif**

> Hazırlayanlar: Proje Ekibi (3 Kişi) | Mart 2025 | Versiyon 3.0 — GİZLİ
> Domain: **deelmarkt.com ✅** | **deelmarkt.eu ✅** (satın alındı)
> Audit: Senior Staff Engineer Review v3.0 — 15 yeni bulgu tespit edilmiş ve kapatılmıştır.

---

## İçindekiler

1. [Yönetici Özeti](#1-yönetici-özeti)
2. [Pazar Analizi ve Fırsatlar](#2-pazar-analizi-ve-fırsatlar)
3. [Rekabet Analizi ve Farklılaşma Stratejisi](#3-rekabet-analizi-ve-farklılaşma-stratejisi)
4. [Ürün Mimarisi ve Geliştirme Metodolojisi](#4-ürün-mimarisi-ve-geliştirme-metodolojisi)
5. [Teknoloji Altyapısı Mimarisi](#5-teknoloji-altyapısı-mimarisi)
6. [Güvenlik Mimarisi ve Uyum](#6-güvenlik-mimarisi-ve-uyum)
7. [Gözlemlenebilirlik ve Güvenilirlik Mühendisliği](#7-gözlemlenebilirlik-ve-güvenilirlik-mühendisliği)
8. [AI/ML Mühendisliği ve MLOps](#8-aiml-mühendisliği-ve-mlops)
9. [Kalite Standartları ve Geliştirme Süreçleri](#9-kalite-standartları-ve-geliştirme-süreçleri)
10. [Organizasyon Yapısı ve Yönetim Planlaması](#10-organizasyon-yapısı-ve-yönetim-planlaması)
11. [Risk Analizi ve Yönetim Stratejileri](#11-risk-analizi-ve-yönetim-stratejileri)
12. [Kritik Başarı Faktörleri (KSF)](#12-kritik-başarı-faktörleri-ksf)
13. [Proje Yol Haritası ve Zaman Planlaması](#13-proje-yol-haritası-ve-zaman-planlaması)
14. [Gelir Modeli ve Finansal Projeksiyon](#14-gelir-modeli-ve-finansal-projeksiyon)
15. [Mimari Karar Kayıtları (ADR)](#15-mimari-karar-kayıtları-adr)
16. [Sonuç ve Stratejik Öneriler](#16-sonuç-ve-stratejik-öneriler)
17. [Tier-1 Audit v2.0 — Kapatılan Bulgular](#17-tier-1-audit-v20--kapatılan-bulgular)
18. [Tier-1 Audit v3.0 — Yeni Bulgular ve Revizyonlar](#18-tier-1-audit-v30--yeni-bulgular-ve-revizyonlar)

---

## 1. Yönetici Özeti

Bu rapor, Hollanda'nın önde gelen online ikinci el ve sınıflı ilanlar platformu **Marktplaats.nl**'ye karşı rekabetçi ve yenilikçi bir alternatif geliştirmeye yönelik kapsamlı bir fizibilite ve strateji belgesidir. 3 kişilik proje ekibi tarafından hazırlanan bu çalışma; pazar analizi, üretim kalitesinde teknoloji mimarisi, ürün stratejisi, organizasyon yapısı ve finansal projeksiyon konularını Google, Amazon ve Netflix gibi lider teknoloji şirketlerinin metodolojilerinden ilham alarak ele almaktadır.

Platform adı: **DeelMarkt**. "Deel" Hollandaca "paylaş/parça" anlamına gelir — sharing economy ve circular economy anlatısını doğrudan isimde taşır. Domainler: **deelmarkt.com** ve **deelmarkt.eu** başarıyla satın alınmıştır.

> **Temel Bulgu:** Hollanda dijital pazar büyüklüğü 2023'te 6,01 Mrd. USD olup 2030'a kadar %11,5 CAGR ile 13,03 Mrd. USD'a ulaşması beklenmektedir. Marktplaats 48 milyon aylık ziyaretle lider olmakla birlikte; AI kişiselleştirme, güvenli ödeme entegrasyonu, DSA uyumu ve genç kullanıcı deneyimi açıklarından muzdariptir.

### 1.1 Marka Stratejisi — DeelMarkt

"Deel" (paylaş/parça) + "Markt" (pazar) birleşimi:

- **Yerel güven:** Hollandaca köklü, Belçika Flamancasında da doğal
- **Anlam uyumu:** Sharing economy + circular economy mesajını ismin içinde taşır
- **Uluslararası ölçek:** "Markt" tüm Germen dillerde anlaşılır; "Deel" İngilizce konuşanlara "deal" (anlaşma) çağrışımı yapar
- **Domain avantajı:** .com ve .eu birlikte — hem küresel hem AB-yerel konumlama
- **Tagline önerisi:** *"Deel wat je hebt"* (Sahip olduklarını paylaş)

### 1.2 Stratejik Vizyon ve Misyon

**Vizyon:** 2028 yılına kadar Hollanda'nın en güvenilir, en akıllı ve en kullanıcı dostu ikinci el ve sınıflı ilanlar platformu olmak; Benelux bölgesine yayılarak Avrupa'da ölçeklenebilir bir pazar yeri inşa etmek.

**Misyon:** Alıcılar ve satıcılar arasında güvenli, şeffaf ve eğlenceli bir alışveriş deneyimi sunarak döngüsel ekonomiye katkıda bulunmak ve toplumsal israfı azaltmak.

### 1.3 Özet Tablo

| Parametre | Değer / Hedef |
|---|---|
| Platform Adı | DeelMarkt |
| Domain (.com) | deelmarkt.com ✅ (satın alındı) |
| Domain (.eu) | deelmarkt.eu ✅ (satın alındı) |
| Tagline | "Deel wat je hebt" |
| Hedef Pazar | Hollanda (öncelikli), Belçika, Almanya (genişleme) |
| Kullanıcı Hedefi (Yıl 1) | 100.000 aktif kullanıcı |
| Kullanıcı Hedefi (Yıl 3) | 3 milyon aktif kullanıcı |
| Başlangıç Ekip Büyüklüğü | 3 kurucu + 5 ilk işe alım |
| MVP Lansman Süresi | 6 ay |
| Tahmini İlk Yıl Geliri | € 600.000 – € 900.000 |
| Tahmini Runway | 18 ay (bootstrap) |
| Temel Farklılaşma | AI eşleştirme, güvenli escrow, çok dilli, sürdürülebilirlik |
| Birincil Gelir Kaynağı | Escrow komisyonu, premium listeler, kargo, reklam |
| Uyum Gereksinimleri | GDPR, DSA, PSD2, AML/KYC |
| Rapor Versiyonu | v3.0 — 15 yeni Tier-1 bulgu kapatıldı |

---

## 2. Pazar Analizi ve Fırsatlar

### 2.1 Hollanda Dijital Pazar Büyüklüğü

Hollanda, Avrupa'nın en gelişmiş e-ticaret pazarlarından biridir. 2024 yılında toplam online tüketici harcaması yaklaşık 36 milyar Euro'ya ulaşmış; kişi başına 1.238 Euro ile Avrupa ortalamasının belirgin biçimde üzerinde seyretmiştir.

| Segment | 2023 | 2030 Tahmini | CAGR |
|---|---|---|---|
| Toplam Dijital Pazar | 6,01 Mrd. USD | 13,03 Mrd. USD | %11,5 |
| C2C / Sınıflı İlanlar | ~1,2 Mrd. USD | ~2,6 Mrd. USD | %11,8 |
| Fiziksel Ürünler (İkinci El) | ~900 M. USD | ~2,1 Mrd. USD | %12,9 |
| Dijital Ürünler | ~300 M. USD | ~750 M. USD | %13,7 |
| Hizmetler | ~400 M. USD | ~900 M. USD | %12,2 |

### 2.2 Mevcut Pazar Oyuncuları

| Platform | Kategori | Aylık Ziyaret | Model | Güçlü Yönleri |
|---|---|---|---|---|
| Marktplaats.nl | Yatay C2C / B2C | ~48 milyon | Ücretsiz + Premium | Marka, geniş içerik |
| Bol.com | B2C Marketplace | ~81,8 milyon | Komisyon %5–20 | Müşteri sadakati |
| Amazon.nl | B2C Marketplace | ~29,1 milyon | FBA + Komisyon | Küresel lojistik |
| Vinted | C2C Moda | Hızlı büyüme | Alıcı hizmet bedeli | Genç kitle, UX |
| Facebook Marketplace | C2C Yerel | Çok yüksek | Ücretsiz | Sosyal ağ |
| eBay.nl | Açık artırma | ~2 milyon | Komisyon | Niş koleksiyon |
| Catawiki | Açık artırma | Niş | ~%12,5 komisyon | Otantikasyon |

### 2.3 Pazar Boşlukları ve Fırsatlar

- **Genç kullanıcı (18–35 yaş) boşluğu:** Marktplaats kullanıcı tabanının ağırlığı 45–54 yaş grubundadır.
- **Expat ve çok dilli destek eksikliği:** Hollanda'da 1,5M+ expat; Marktplaats'ın İngilizce deneyimi minimaldir.
- **Güvenli ödeme / escrow altyapısı yetersizliği:** Nakit işlem baskınlığı; entegre escrow sistemi yoktur.
- **AI ve kişiselleştirme eksikliği:** Algoritmik öneri, otomatik fiyatlandırma ve sahte ilan tespiti açıkları mevcuttur.
- **Sürdürülebilirlik anlatısı boşluğu:** DeelMarkt ismi bu fırsatı doğrudan adresler.
- **DSA uyumsuzluğu riski:** 2024'ten itibaren AB'de zorunlu; Marktplaats yavaş ilerlemektedir.

### 2.4 DeelMarkt Marka Avantajı (Pazar Konumlaması)

"Deel" kelimesinin çift anlamı güçlü bir konumlama fırsatı sunar:

- Hollandaca: "paylaş" → sharing economy, circular economy
- İngilizce: "deal" → uygun fiyat, anlaşma → değer odaklı alışveriş
- Almanca: "Teil" (parça) → yakın çağrışım, BE/DE genişlemesinde doğal

Bu çok katmanlı anlam yapısı, hem NL yerel kullanıcısına hem de uluslararası expat kitlesine aynı anda hitap etmesini sağlar.

---

## 3. Rekabet Analizi ve Farklılaşma Stratejisi

### 3.1 Marktplaats SWOT Analizi

**Güçlü Yönler**
- 25+ yıllık marka güveni; 48M aylık ziyaret, günlük 350K yeni ilan
- 36 kategori; Adevinta (13,4 Mrd. USD değerleme) finansal desteği
- Kapsamlı içerik kütüphanesi ve SEO otoritesi

**Zayıf Yönler**
- Kullanıcı arayüzü "legacy" hissi; genç kullanıcı kaybı hızlanıyor
- Güvenli ödeme / escrow eksikliği; dolandırıcılık şikayetleri kronik
- AI/ML kişiselleştirme neredeyse yok
- Çok dilli deneyim minimal (1,5M+ expat göz ardı ediliyor)
- Satıcı ücreti (€4–5/hafta) Facebook Marketplace'e kaçışı tetikliyor
- DSA uyum sürecinde yavaş ilerleme

**Fırsatlar (DeelMarkt için)**
- Genç kullanıcı segmenti açığı
- Expat pazarı büyümesi
- "Deel" markasının sharing economy trendine doğal uyumu

**Tehditler**
- Vinted'in kategori genişlemesi
- Facebook Marketplace'in ücretli özelliklere geçişi
- Amazon/eBay'in C2C segmentine girişi

### 3.2 Özellik Karşılaştırma Matrisi

| Özellik | Vinted | eBay | FB Marketplace | Mobile.de | DeelMarkt |
|---|---|---|---|---|---|
| Otomatik kargo entegrasyonu | ✅ | ✅ | ❌ | ❌ | ✅ |
| Alıcı güvence / escrow | ✅ | ✅ | Kısmi | ❌ | ✅ |
| AI fiyat önerisi | ❌ | Kısmi | ❌ | Kısmi | ✅ |
| Çok dilli arayüz (EN/DE/FR) | ✅ | ✅ | ✅ | Kısmi | ✅ |
| KYC / Kimlik doğrulama | Kısmi | ✅ | ❌ | ✅ | ✅ (Progresif) |
| Satıcı mağaza sayfası | Kısmi | ✅ | Kısmi | ✅ | ✅ |
| Sürdürülebilirlik rozetleri | ✅ | ❌ | ❌ | ❌ | ✅ |
| AI sohbet asistanı | ❌ | Kısmi | ❌ | ❌ | ✅ |
| Görsel arama | ❌ | ✅ | ❌ | ❌ | ✅ |
| Takas (Swap) işlemi | ❌ | ❌ | ❌ | ❌ | ✅ |
| DSA uyumlu şeffaflık | Kısmi | ✅ | Kısmi | ❌ | ✅ |
| Progressive KYC | ❌ | ❌ | ❌ | ❌ | ✅ (v3.0 yeni) |
| Mobile deep linking | Temel | ✅ | ✅ | Kısmi | ✅ (v3.0 yeni) |
| Multi-domain routing | — | ✅ | ✅ | Kısmi | ✅ (v3.0 yeni) |

### 3.3 DeelMarkt Farklılaşma Stratejisi

**Eksen 1 — Güven ve Güvenlik (Trust-First)**
Hollanda pazarının kronik acı noktası olan güvensizliği çözmek: zorunlu kimlik doğrulama (iDIN/DigID), escrow ödeme sistemi, AI + kural tabanlı sahte ilan tespiti ve DSA uyumlu şeffaflık dashboard'u.

**Eksen 2 — Akıllı Deneyim (AI-Native)**
Amazon öneri motorlarından ve Netflix kişiselleştirme altyapısından ilham alarak: kişiselleştirilmiş ilan önerileri, dinamik fiyatlandırma tavsiyeleri, görsel arama ve konuşma tabanlı AI asistan.

**Eksen 3 — Topluluk ve Sürdürülebilirlik ("Deel wat je hebt")**
"Deel" markasının doğasından gelen avantaj: CO2 tasarruf rozetleri, takas (swap) işlemleri, topluluk forumları ve sürdürülebilirlik sertifika programı.

---

## 4. Ürün Mimarisi ve Geliştirme Metodolojisi

### 4.1 Ürün Katmanları

**Katman 1 — Temel Platform (Core)**
- İlan oluşturma ve yönetim sistemi (web + mobil)
- Dutch language Elasticsearch tabanlı arama ve filtreleme motoru *(v3.0 güncellendi)*
- Kullanıcı hesap yönetimi ve iDIN kimlik doğrulama
- In-app mesajlaşma (WebSocket + Redis Pub/Sub)
- Temel ödeme altyapısı (iDEAL, Mollie)
- Universal Links / App Links ile mobile deep linking *(v3.0 yeni)*

**Katman 2 — Güven ve Güvenlik (Trust Layer)**
- Progressive KYC modülü — eşik bazlı, sürtüşme minimize *(v3.0 yeni)*
- Escrow ödeme akışı + EventStoreDB olay log'u + double-entry ledger *(v3.0 güncellendi)*
- AI + kural tabanlı sahte ilan tespiti
- Kullanıcı puanlama, yorum ve dispute resolution iş akışı
- DSA uyumlu şeffaflık raporlama modülü
- Mollie webhook idempotency + exponential backoff retry *(v3.0 yeni)*

**Katman 3 — Akıllı Özellikler (Intelligence Layer)**
- AI fiyat öneri motoru (XGBoost + piyasa verisi)
- Kişiselleştirilmiş ilan önerme (Two-Tower + content-based)
- Görsel arama (CLIP + Pinecone vektör veritabanı)
- Otomatik kategori tespiti (NLP + görsel ensemble)
- CO2 tasarruf hesaplayıcı ve sürdürülebilirlik rozetleri

**Katman 4 — Büyüme ve Monetizasyon**
- Premium satıcı dashboard'u (analytics, bulk listing)
- PostNL, DHL, GLS kargo etiket entegrasyonu
- ASO (App Store Optimization) varlıkları *(v3.0 yeni)*
- BNPL entegrasyonu (Klarna/Afterpay — Faz 2)
- Canlı müzayede motoru (Faz 2)

### 4.2 MVP Kapsamı (İlk 6 Ay)

| MVP Özelliği | Öncelik | Süre | Versiyon |
|---|---|---|---|
| İlan oluşturma (web + mobil) | P0 — Kritik | 6 hf | v2.0 |
| Elasticsearch arama + NL analyzer | P0 — Kritik | 4 hf | v3.0 güncellendi |
| Kullanıcı kaydı / iDIN + Progressive KYC | P0 — Kritik | 3 hf | v3.0 güncellendi |
| In-app mesajlaşma (WebSocket) | P0 — Kritik | 3 hf | v2.0 |
| iDEAL / Mollie ödeme | P0 — Kritik | 4 hf | v2.0 |
| Escrow akışı + EventStoreDB + ledger | P1 — Yüksek | 5 hf | v3.0 güncellendi |
| Mollie webhook idempotency + retry | P1 — Yüksek | 1 hf | v3.0 yeni |
| Outbox pattern (transactional messaging) | P1 — Yüksek | 2 hf | v3.0 yeni |
| Dispute resolution iş akışı | P1 — Yüksek | 3 hf | v2.0 |
| DSA uyum şeffaflık modülü | P1 — Yüksek | 2 hf | v2.0 |
| Feature flag altyapısı (Unleash) | P1 — Yüksek | 1 hf | v2.0 |
| AI sahte ilan tespiti (temel) | P1 — Yüksek | 4 hf | v2.0 |
| Kargo etiket entegrasyonu | P1 — Yüksek | 3 hf | v2.0 |
| Universal Links / App Links | P1 — Yüksek | 1 hf | v3.0 yeni |
| Multi-domain routing (Cloudflare) | P1 — Yüksek | 1 hf | v3.0 yeni |
| Image processing pipeline | P2 — Orta | 2 hf | v3.0 yeni |
| Push bildirim altyapısı (FCM/APNs) | P2 — Orta | 2 hf | v2.0 |
| Admin moderasyon paneli | P2 — Orta | 3 hf | v2.0 |

### 4.3 Geliştirme Metodolojisi

- **Çalışma Modeli:** Agile / Scrum + OKR (3 aylık döngüler)
- **Sprint Süresi:** 2 hafta; teknik borç sprinti her 4 sprint'te 1
- **Araçlar:** Linear, Figma, GitHub, Notion, Unleash (feature flags)
- **Deployment:** Blue-green (MVP) → Canary %5/%20/%100 (Faz 2+)
- **Test:** ≥%80 unit, ≥%60 integration coverage; CI'da zorunlu
- **Kullanıcı Testi:** Her sprint sonunda 5–10 kullanıcıyla guerrilla test
- **ADR Kültürü:** Her önemli mimari karar yazılı; bilgi tek kişiye bağlı olmamalı

---

## 5. Teknoloji Altyapısı Mimarisi

> **v3.0 Audit Notu:** Bu bölüm 15 yeni bulgu ile genişletilmiştir. Tüm değişiklikler §18'de özetlenmiştir.

### 5.1 Mimari Prensip: Modular Monolith + Strangler Fig

DeelMarkt "Modular Monolith First, Microservices When Justified" prensibini benimser. 3 kişilik kurucu ekip için erken microservices operasyonel yük olur. Strangler Fig Pattern ile yüksek yük modülleri (AI, Arama, Bildirim) Faz 2'de ayrı servise çıkarılır.

### 5.2 Frontend Mimarisi

| Katman | Teknoloji | Gerekçe |
|---|---|---|
| Web Uygulaması | Next.js 15 (App Router) | SSR/SSG hibrit, Core Web Vitals, SEO |
| Mobil Uygulama | React Native + Expo | iOS + Android tek kod tabanı, OTA güncelleme |
| UI Sistemi | Tailwind CSS + Radix UI | Erişilebilir, test edilebilir bileşenler |
| State Yönetimi | Zustand + TanStack Query | Net istemci/sunucu ayrımı |
| İnternasyonalizasyon | next-intl | NL, EN, DE, FR — Faz 1'den itibaren |
| Analytics | PostHog | GDPR uyumlu, self-hostable, session recording |
| A/B Testi | Statsig | Feature flag + deney yönetimi |
| Mobile Deep Linking | Branch.io + Universal Links | iOS App Links + Android App Links *(v3.0)* |
| Multi-domain | Cloudflare geo-routing + hreflang | .com → küresel; .eu → AB kullanıcıları *(v3.0)* |

**Performans Bütçesi (CI'da zorunlu kontrol):**
- JS bundle: < 200 KB gzip
- LCP: < 2,5 sn (mobil 4G)
- CLS: < 0,1 / INP: < 200 ms
- Lighthouse skoru: ≥ 90 (tüm kategoriler)

### 5.3 Backend Mimarisi

```
┌──────────────────────────────────────────────────────────────┐
│          Cloudflare (CDN + WAF + DDoS + Geo-routing)         │
└──────────────────────┬───────────────────────────────────────┘
                       │
┌──────────────────────▼───────────────────────────────────────┐
│                   API Gateway (Kong)                         │
│      Rate Limiting │ Auth │ Routing │ Logging │ Versioning    │
└──────────┬─────────────────────────────────┬─────────────────┘
           │                                 │
    ┌──────▼──────┐                   ┌──────▼──────┐
    │ DeelMarkt   │                   │ AI Service  │
    │ Core(NestJS)│                   │  (FastAPI)  │
    └──────┬──────┘                   └──────┬──────┘
           │                                 │
    ┌──────▼─────────────────────────────────▼──────┐
    │                  Data Layer                    │
    │  PostgreSQL │ Redis Cluster │ Elasticsearch    │
    │  S3/CF CDN  │ EventStoreDB  │ Redshift         │
    │  Pinecone   │ Kafka (CDC)   │ Outbox Table     │
    └────────────────────────────────────────────────┘
```

| Bileşen | Teknoloji | Yapılandırma / Not |
|---|---|---|
| API Çerçevesi | NestJS (TypeScript) | CQRS modülü; komut/sorgu ayrımı |
| API Stili | REST `/api/v1/` + GraphQL (Faz 2) | Versiyonlama zorunlu |
| Veritabanı (OLTP) | PostgreSQL 16 | Multi-AZ RDS; read replica × 2 |
| PgBouncer | Transaction mode | pool_size=20, max_client_conn=100 *(v3.0)* |
| Veri Ambarı (OLAP) | Amazon Redshift Serverless | OLTP'den ayrı; BI + ML |
| CDC Pipeline | Debezium → Kafka → Elasticsearch | PG → ES senkronizasyonu *(v3.0)* |
| Outbox Table | PostgreSQL `outbox` tablosu | Transactional messaging *(v3.0)* |
| Cache | Redis Cluster (ElastiCache) | Sentinel; 3 node; event-driven invalidation *(v3.0)* |
| Arama | Elasticsearch 8 | `dutch` analyzer + ILM + hot-warm-cold |
| Olay Deposu | EventStoreDB | Escrow immutable log + double-entry ledger |
| Mesaj Kuyruğu | Amazon SQS + SNS | Garantili iletim + DLQ |
| Gizli Yönetimi | AWS Secrets Manager | API anahtarları asla env var'da değil |
| Dosya Depolama | AWS S3 + CloudFront | ClamAV virüs tarama + image pipeline |
| Image Pipeline | Lambda (Sharp) | WebP/AVIF dönüşüm + thumbnail *(v3.0)* |
| E-posta | AWS SES + Postmark | Transactional + bulk ayrımı |
| SMS / WhatsApp | CM.com (MessageBird) | WhatsApp Business penetrasyonu yüksek |
| CDN / DDoS | Cloudflare Pro | WAF + geo-routing + cache rules *(v3.0)* |

### 5.4 Elasticsearch — Dutch Language Analyzer *(v3.0 Yeni)*

Hollanda dili için varsayılan analyzer yetersizdir. DeelMarkt'ın `dutch` analyzer konfigürasyonu:

```json
{
  "settings": {
    "analysis": {
      "analyzer": {
        "deelmarkt_dutch": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": [
            "lowercase",
            "dutch_stop",
            "dutch_stemmer",
            "dutch_keywords",
            "asciifolding"
          ]
        }
      },
      "filter": {
        "dutch_stop": { "type": "stop", "stopwords": "_dutch_" },
        "dutch_stemmer": { "type": "stemmer", "language": "dutch" },
        "dutch_keywords": { "type": "keyword_marker", "keywords": ["fiets", "auto", "huis"] }
      }
    }
  }
}
```

Bu konfigürasyon sayesinde:
- "fietsbanden" → "fietsband" (compound word decomposition)
- "tweedehands" → "tweedehands" (keyword koruması)
- "gebruikte" ↔ "gebruikt" ↔ "gebruik" (stemming eşleştirmesi)

### 5.5 CDC-Based Search Indexing Pipeline *(v3.0 Yeni)*

```
PostgreSQL (listings table)
  → Debezium CDC connector (WAL okuma)
  → Kafka topic: deelmarkt.listings.changes
  → Kafka consumer (NestJS worker)
  → Elasticsearch index güncelleme
  → Cache invalidation event (Redis Pub/Sub)
```

**Neden önemli:** Dual-write (hem DB hem ES'e doğrudan yazma) veri tutarsızlığı riski taşır. CDC yaklaşımı PostgreSQL'i gerçek kaynak (source of truth) olarak korur; Elasticsearch yalnızca derive edilmiş görünüm olur.

**Near-real-time gecikme hedefi:** < 500 ms (P95)

### 5.6 Cache Invalidation Stratejisi *(v3.0 Yeni)*

| Cache Tipi | TTL | Invalidation Tetikleyici |
|---|---|---|
| Listing detay sayfası | 5 dk | `listing.updated`, `listing.sold`, `listing.deleted` |
| Arama sonuçları | 2 dk | `listing.created`, `listing.updated`, kategori değişimi |
| Kullanıcı profili | 10 dk | `user.updated`, yorum eklenmesi |
| AI önerileri | 30 dk | `user.purchase`, `user.favorite` |
| Kategori sayfası | 15 dk | Yeni ilan sayısı eşiği |

Redis Pub/Sub üzerinden `cache:invalidate:{key}` event'leri ile event-driven invalidation uygulanır. Stale-while-revalidate pattern kullanılarak kullanıcı deneyimi korunur.

### 5.7 Escrow Double-Entry Accounting Ledger *(v3.0 Yeni)*

PSD2 finansal denetim uyumu için EventStoreDB olaylarına ek olarak double-entry ledger zorunludur:

```
DEBIT  buyer.wallet       100.00 EUR  # Alıcıdan tahsilat
CREDIT escrow.holding     100.00 EUR  # Platform escrow hesabı

→ Teslimat onayında:
DEBIT  escrow.holding     100.00 EUR
CREDIT seller.wallet       97.50 EUR  # %2.5 komisyon sonrası
CREDIT platform.revenue     2.50 EUR
```

Her entry: `entry_id, debit_account, credit_account, amount, currency, transaction_id, created_at, idempotency_key`

**Reconciliation:** Günlük otomatik reconciliation job — EventStoreDB event sayısı ile ledger entry sayısı eşleşmeli. Uyumsuzluk → PagerDuty SEV-2 alert.

### 5.8 Mollie Webhook — Idempotency + Retry *(v3.0 Yeni)*

```typescript
// Idempotency key: webhook işleme
async processWebhook(payload: MollieWebhookDto): Promise<void> {
  const idempotencyKey = `mollie:webhook:${payload.id}`;
  const alreadyProcessed = await this.redis.set(
    idempotencyKey, '1', 'EX', 86400, 'NX'
  );
  if (!alreadyProcessed) return; // Duplicate — skip

  await this.escrowService.processPaymentEvent(payload);
}
```

**Retry politikası:** Mollie webhook başarısız → SQS dead-letter queue → exponential backoff (1s, 2s, 4s, 8s, max 5 deneme) → 5. denemede de başarısız → PagerDuty SEV-1 (finansal veri kaybı riski).

### 5.9 Image Processing Pipeline *(v3.0 Yeni)*

```
Upload → S3 (raw/) → Lambda trigger (Sharp)
  → Resize: thumbnail (200×200), medium (800×600), large (1600×1200)
  → Convert: WebP (primary) + AVIF (modern browsers)
  → Virus scan: ClamAV
  → Output: S3 (processed/{listing_id}/)
  → CloudFront URL üretimi
```

**Kurallar:**
- Max upload boyutu: 15 MB per image, max 12 image per listing
- Kabul edilen formatlar: JPEG, PNG, HEIC, WebP
- HEIC → JPEG dönüşüm (iOS kullanıcıları için)
- Metadata stripping (EXIF — GDPR: konum verisi)
- CDN path: `cdn.deelmarkt.com/listings/{id}/{size}.webp`

### 5.10 PgBouncer Konfigürasyonu *(v3.0 Yeni)*

```ini
[pgbouncer]
pool_mode = transaction        # NestJS için doğru mod
max_client_conn = 200          # Uygulama katmanı maksimum
default_pool_size = 20         # PostgreSQL'e gerçek bağlantı
reserve_pool_size = 5          # Ani yük için yedek
reserve_pool_timeout = 3
max_db_connections = 100       # RDS max_connections / 2
server_idle_timeout = 600
```

**Neden transaction mode:** Session mode NestJS async context ile uyumsuz ve bağlantıları gereksiz açık tutar. Transaction mode doğru seçimdir.

### 5.11 Multi-Domain Routing Stratejisi *(v3.0 Yeni)*

| Domain | Hedef Kitle | Routing Kuralı |
|---|---|---|
| deelmarkt.eu | AB kullanıcıları (NL, BE, DE, FR) | Cloudflare Worker geo-routing EU → .eu |
| deelmarkt.com | Küresel (expat, uluslararası) | Default; Hollanda dışı trafik |
| www.deelmarkt.nl | Yedek (nabız takibi için reserve edilmeli) | 301 → deelmarkt.eu |

**SEO gereksinimleri:**
- Her dil/bölge için `hreflang` tag: `<link rel="alternate" hreflang="nl-NL" href="https://deelmarkt.eu/nl/">`
- Canonical URL her sayfada tanımlı (duplicate content önleme)
- `x-robots-tag` header ile development/staging ortamları `noindex`

### 5.12 Universal Links / App Links *(v3.0 Yeni)*

**iOS Universal Links:** `/.well-known/apple-app-site-association` endpoint'i:
```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "TEAMID.nl.deelmarkt.app",
      "paths": ["/listings/*", "/users/*", "/categories/*"]
    }]
  }
}
```

**Android App Links:** `/.well-known/assetlinks.json` endpoint'i + `AndroidManifest.xml` intent filter

**Kullanım senaryoları:** E-posta bildirimindeki ilan linkine tıklandığında → uygulama açılır (browser değil); sosyal medya paylaşımı → app deep link; kargo takip bildirimi → ilgili işlem sayfası.

### 5.13 Ölçeklenebilirlik Tasarımı

| Bileşen | Ölçekleme Stratejisi | Kapasite Hedefi |
|---|---|---|
| NestJS API | Horizontal (ECS Fargate) | 10.000 RPS |
| PostgreSQL | Read replica × 2; PgBouncer tx mode | 50M satır/tablo |
| Redis | ElastiCache Cluster (6 node) | 1M ops/sn |
| Elasticsearch | 3 shard × 2 replica; ILM; dutch analyzer | 100M+ ilan |
| Kafka (CDC) | 3 broker; replication factor 3 | 100K msg/sn |
| SQS | Standart kuyruk + DLQ | Sınırsız |

---

## 6. Güvenlik Mimarisi ve Uyum

### 6.1 OWASP Top 10 Hafifletme Planı

| OWASP Riski | Hafifletme |
|---|---|
| A01 — Broken Access Control | RBAC (NestJS Guards), kaynak bazlı yetkilendirme, JWT 15 dak + refresh token |
| A02 — Cryptographic Failures | AES-256 PII şifreleme, TLS 1.3 zorunlu, HSTS, sertifika pinning (mobil) |
| A03 — Injection | TypeORM parameterized queries, Joi/Zod input validation, DOMPurify (frontend) |
| A04 — Insecure Design | Threat modeling her özellik için, escrow'da 4-göz prensibi |
| A05 — Security Misconfiguration | Terraform IaC, drift detection (AWS Config), CIS benchmark |
| A06 — Vulnerable Components | Snyk (CI'da blocker), dependabot, quarterly dep audit |
| A07 — Auth Failures | iDIN MFA, rate limiting giriş denemesi, bcrypt (cost 12) |
| A08 — Data Integrity Failures | İmzalı S3 URL'leri, webhook HMAC-SHA256 + idempotency *(v3.0)* |
| A09 — Logging Failures | Tüm auth + ödeme olayları yapısal log; PII maskeleme zorunlu |
| A10 — SSRF | Allowlist tabanlı outbound HTTP; metadata endpoint engelleme |

### 6.2 Güvenlik Süreçleri

- **Penetrasyon Testi:** Lansmanöncesi (dış bağımsız firma) + yıllık tekrar
- **SAST:** SonarQube (CI'da zorunlu geçiş)
- **DAST:** OWASP ZAP (staging ortamında haftalık)
- **Secret Tarama:** GitGuardian + GitHub secret scanning
- **Siber Sigorta:** Lansman öncesi €1M+ siber sigorta poliçesi
- **Cloudflare WAF:** Custom rules for NL/BE traffic patterns *(v3.0)*

### 6.3 DSA (Digital Services Act) Uyumu

DSA, Şubat 2024'ten itibaren tüm AB marketplace'leri için yürürlüktedir. DeelMarkt Day 1'den uyumludur:

- **Şeffaf algoritma:** Kullanıcılar ilan sıralamasının nasıl çalıştığını okuyabilmeli
- **Satıcı doğrulaması:** KYBC — ticari satıcılar KVK numarası ile doğrulanır
- **İhbar ve eylem:** Sahte ilan bildirimi 24 saat içinde değerlendirilmeli (yasal zorunluluk)
- **Şeffaflık raporu:** Yıllık moderasyon istatistikleri public yayınlanmalı
- **Algoritma tercih hakkı:** Kullanıcıya "kişiselleştirilmemiş" feed seçeneği sunulmalı

### 6.4 GDPR Uyum Planı

| Gereklilik | Uygulama |
|---|---|
| Rıza yönetimi | Didomi CMP entegrasyonu (IAB TCF 2.2 uyumlu) |
| Erişim hakkı (DSR) | 30 günlük otomatik veri dışa aktarma API'si |
| Silinme hakkı | Async PII silme worker; 30 gün; audit log korunur; EXIF metadata silme *(v3.0)* |
| Veri taşınabilirliği | JSON + CSV export endpoint |
| Veri ihlali bildirimi | PagerDuty → ekip → AP bildirimi (72 saat içinde) |
| Veri sınıflandırması | PII-Kritik (BSN/IBAN): AES-256 + KMS; Standart PII: TLS at-rest |
| Image metadata | EXIF stripping — konum verisi GDPR kapsamında *(v3.0)* |

### 6.5 Progressive KYC — Sürtüşme Minimizasyonu *(v3.0 Yeni)*

Amazon ve eBay'in kanıtladığı progressive KYC yaklaşımı:

| Seviye | Tetikleyici | Gereksinim |
|---|---|---|
| Seviye 0 (Temel) | Kayıt | E-posta + telefon doğrulama |
| Seviye 1 (Alıcı) | İlk mesaj gönderme | — (ek gereksinim yok) |
| Seviye 2 (Satıcı) | İlk ilan oluşturma | iDIN (BSN bazlı kimlik) |
| Seviye 3 (Escrow) | İlk escrow işlemi | Onfido selfie + belge |
| Seviye 4 (Ticari) | Aylık €2.500+ satış | KVK numarası + KYBC |

**Neden önemli:** Tam KYC'yi kayıt anında zorunlu kılmak, kullanıcı kaybını önemli ölçüde artırır. Vinted bu hatayı erken yaptı ve kullanıcı tabanından vazgeçmek zorunda kaldı.

---

## 7. Gözlemlenebilirlik ve Güvenilirlik Mühendisliği

### 7.1 Gözlemlenebilirlik Yığını

| Pillar | Araç | Amaç |
|---|---|---|
| Metrikler | Datadog APM + custom metrics | Latency, throughput, error rate |
| Loglar | Datadog Log Management (JSON) | Debug, audit trail, PII maskeleme |
| Distributed Tracing | OpenTelemetry → Datadog APM | Servis bağımlılığı, root cause |
| Hata Takibi | Sentry | Stack trace, release tracking |
| Uptime (harici) | Betterstack | Bağımsız doğrulama |
| Gerçek Kullanıcı (RUM) | Datadog RUM + Core Web Vitals | Sayfa performansı |
| Synthetics | Datadog Synthetic | Kritik iş akışı (ödeme, ilan oluşturma) |
| CDC Lag | Kafka consumer lag monitoring | Debezium → ES senkronizasyon gecikmesi *(v3.0)* |
| Ledger Reconciliation | Custom reconciliation job | EventStoreDB ↔ ledger uyumu *(v3.0)* |

**OpenTelemetry Kural:** Tüm servisler trace context'i `traceparent` header ile iletmeli. Trace ID log satırlarına inject edilmeli.

### 7.2 SLI / SLO / Error Budget Çerçevesi

| Servis | SLI | SLO | Error Budget (30 gün) |
|---|---|---|---|
| Arama API | Başarılı istek oranı | %99,5 | 216 dak downtime |
| İlan Oluşturma | Başarılı istek oranı | %99,9 | 43 dak downtime |
| Ödeme / Escrow | Başarılı işlem oranı | %99,99 | 4 dak downtime |
| Mesajlaşma | Mesaj iletim oranı | %99,5 | 216 dak downtime |
| Mobil (LCP) | LCP < 3 sn oranı | %95 | — |
| CDC Pipeline | ES senkronizasyon gecikmesi < 1 sn | %99 | *(v3.0)* |
| Webhook İşleme | Başarılı işleme oranı | %99,9 | *(v3.0)* |

**Error Budget Politikası:** Budget %50 tükendiğinde yeni özellik deployu dondurulur.

### 7.3 Alerting Hiyerarşisi

```
Kritik (PagerDuty — anında):
  - Ödeme servisi hata oranı > %1
  - Escrow ledger reconciliation uyumsuzluğu
  - Webhook DLQ'ya düşen mesaj var
  - CDC lag > 5 saniye (arama stale riski)
  - DB bağlantı havuzu > %90 dolu
  - SLO error budget > %50 tüketildi

Yüksek (PagerDuty — 15 dak):
  - API p95 latency > 1 sn (5 dak sürekli)
  - Elasticsearch sağlık durumu sarı
  - Disk kullanımı > %80

Bilgi (Slack — iş saatleri):
  - Deploy tamamlandı
  - Günlük aktif kullanıcı eşiği
  - Cache hit rate < %70 (araştırma tetikleyici)
```

### 7.4 Incident Management

| Seviye | Tanım | Yanıt Süresi | Komuta |
|---|---|---|---|
| SEV-1 | Ödeme / platform çöküşü | 5 dak | CTO (Incident Commander) |
| SEV-2 | Kritik özellik çalışmıyor | 15 dak | On-call mühendis |
| SEV-3 | Bozulma var, kritik değil | 1 saat | Slack bildirim |
| SEV-4 | Kozmetik hata | Bir sonraki sprint | Backlog |

SEV-1 ve SEV-2 için blameless post-mortem zorunlu: 48 saat içinde taslak, 1 hafta içinde yayın.

### 7.5 Deployment Stratejisi ve DR

- **Faz 1:** Blue-green deployment — smoke test → trafik yönlendir → 30 dak izle
- **Faz 2+:** Canary %5 → %20 → %100; otomatik hata bazlı abort
- **RTO:** < 4 saat (SEV-1) | **RPO:** < 1 saat
- **Yedekleme:** PostgreSQL her 1 saat; S3 sürekli versiyonlama
- **Restore Drill:** Ayda 1 kez otomatik restore testi → Slack raporu *(v3.0)*
- **Cross-region:** eu-west-1 → us-east-1 DR; yılda 2 Game Day tatbikatı

---

## 8. AI/ML Mühendisliği ve MLOps

### 8.1 AI Özellikleri ve Teknik Yaklaşım

| Özellik | Model / Yaklaşım | Gecikme Hedefi |
|---|---|---|
| Fiyat Öneri Motoru | XGBoost regression + kategori embedding | < 100 ms |
| Kişiselleştirilmiş Öneriler | Two-Tower (collaborative) + content-based fallback | < 150 ms |
| Görsel Arama | CLIP (ViT-B/32) + Pinecone ANN | < 500 ms |
| Otomatik Kategori Tespiti | Fine-tuned DistilBERT + ResNet ensemble | < 200 ms |
| Sahte İlan Tespiti | XGBoost (kural özellikleri) + GPT-4o (yüksek riskli) | < 1 sn |
| AI Sohbet Asistanı | GPT-4o + RAG (ilan veritabanı) | < 3 sn |

### 8.2 MLOps Standartları

- **Model Versiyonlama:** MLflow Model Registry; her model commit'e bağlı, yeniden üretilebilir
- **A/B Testi:** Her yeni model %5 shadow trafik → istatistiksel anlamlılık sonrası artırım
- **Model Drift Tespiti:** Evidently AI — haftalık; PSI > 0.2 → yeniden eğitim
- **Veri Kalite Geçidi:** Great Expectations — eğitim pipeline'ında zorunlu
- **Özellik Deposu:** Feast (offline + online) — eğitim/servis tutarsızlığını önler
- **Kural Tabanlı Yedek:** AI başarısız → kural tabanlı sistem devreye girer
- **Geri Bildirim Döngüsü:** Kullanıcı aksiyonları → Redshift → haftalık model güncelleme

---

## 9. Kalite Standartları ve Geliştirme Süreçleri

### 9.1 Yazılım Kalite Standartları

| Metrik | Hedef | Ölçüm | CI'da Zorunlu |
|---|---|---|---|
| Unit Test Kapsamı | ≥ %80 | Jest / Pytest | Evet (blocker) |
| Integration Test | ≥ %60 kritik akışlar | Supertest / Pytest | Evet (blocker) |
| API Yanıt Süresi p95 | < 200 ms | Datadog APM | Alerting |
| API Yanıt Süresi p99 | < 1 sn | Datadog APM | Alerting |
| LCP (Web) | < 2,5 sn | Lighthouse CI | PR uyarısı |
| SLA (Ödeme) | %99,99 | SLO dashboard | Error budget |
| Kritik Hata Oranı | < %0,1 | Sentry | Alerting |
| CVSS ≥ 7 açık | 0 | Snyk | Evet (blocker) |
| Lighthouse Skoru | ≥ 90 (tüm kategoriler) | Lighthouse CI | PR uyarısı |
| WCAG 2.2 AA | Tam uyum | axe-core CI | Evet (blocker) *(v3.0)* |
| DORA — Deploy Freq. | Günlük | DORA dashboard | KPI |
| DORA — MTTR | < 1 saat | PagerDuty | KPI |

### 9.2 İçerik Moderasyon SLA'ları

- **Otomatik tespit:** < 30 saniye
- **Topluluk bildirimi:** < 4 saat (iş saatlerinde)
- **DSA ihbar:** < 24 saat (yasal zorunluluk)
- **İtiraz yanıtı:** < 72 saat

### 9.3 WCAG 2.2 Güncellemesi *(v3.0)*

v2.0 WCAG 2.1'e atıfta bulunuyordu. WCAG 2.2, Ekim 2023'te yayınlandı ve mevcut standarttır. Yeni kriterler:

- **2.4.11 Focus Appearance:** Klavye odak göstergesi minimum 2px, kontrast 3:1
- **2.4.12 Focus Not Obscured:** Odaklanmış öğe yapışkan header/footer tarafından gizlenemez
- **2.5.7 Dragging Movements:** Tüm sürükle-bırak işlevleri tek işaretçiyle yapılabilmeli
- **2.5.8 Target Size:** Minimum 24×24 CSS piksel tıklanabilir alan
- **3.2.6 Consistent Help:** Yardım mekanizmaları sayfa genelinde tutarlı konumda

---

## 10. Organizasyon Yapısı ve Yönetim Planlaması

### 10.1 Kurucu Ekip (3 Kişi)

| Unvan | Sorumluluk Alanları | Temel Yetkinlikler |
|---|---|---|
| CEO / Ürün Direktörü | Şirket vizyonu, ürün yol haritası, yatırımcı ilişkileri, DSA uyum, hukuki yapı | Ürün yönetimi, strateji, fundraising |
| CTO / Baş Mühendis | Teknoloji mimarisi, geliştirme, güvenlik, MLOps, ADR yönetimi | Full-stack, sistem tasarımı, AI/ML, DevOps |
| CMO / Büyüme Direktörü | Pazarlama, kullanıcı edinimi, marka, topluluk, ASO *(v3.0)* | Growth hacking, SEO, içerik, sosyal medya |

### 10.2 Hukuki Yapı *(v3.0 Yeni)*

v2.0'da yalnızca "Hollanda BV" belirtilmişti. Uluslararası genişleme için yetersizdir.

**Önerilen yapı:**
```
DeelMarkt Holding B.V. (Amsterdam)
  └── DeelMarkt Operations B.V. (işletme şirketi — NL)
  └── DeelMarkt Belgium BV (Faz 3 — BE genişleme)
  └── DeelMarkt GmbH (Faz 3 — DE genişleme)
```

**Avantajlar:**
- IP haklarını holding'de tutmak (royalty optimizasyonu)
- Her ülke için bağımsız vergi sorumluluğu
- Yatırımcı sermayesi holding seviyesinde toplanır
- Bir ülkedeki yasal risk diğer ülkeleri etkilemez

### 10.3 İlk Dönem İşe Alım Planı

| Pozisyon | Ay | Öncelik Nedeni |
|---|---|---|
| UX/UI Tasarımcı | 2. Ay | MVP kalitesi — WCAG 2.2 uyumu |
| Backend Mühendisi (Ödeme/CDC uzmanı) | 3. Ay | Escrow + EventStoreDB + Kafka CDC karmaşıklığı |
| Frontend / React Native Mühendisi | 3. Ay | Web + mobil; Universal Links implementasyonu |
| Güven ve Güvenlik / Müşteri Başarı | 6. Ay | Moderasyon + DSA uyum süreçleri |
| Veri Mühendisi | 9. Ay | Kafka, Debezium, Redshift, ML pipeline |

### 10.4 OKR Sistemi

**Q1 — Objective: Güvenilir MVP Lansmanlamak**
- KR1: Tüm P0 özellikler 6 ay içinde canlıda
- KR2: Ödeme escrow hata oranı < %0,1
- KR3: App Store / Google Play ≥ 4,2

**Q2 — Objective: Güven ve Uyumu Ölçülebilir Kılmak**
- KR1: Progressive KYC Seviye 2 tamamlama oranı > %80
- KR2: Dolandırıcılık şikayet oranı < %0,3
- KR3: DSA ihbar yanıt süresi %100 < 24 saat

**Q3 — Objective: AI Değer Yaratmayı Kanıtlamak**
- KR1: AI fiyat önerisi kabul oranı > %25
- KR2: Öneri tıklama oranı > %15
- KR3: Görsel arama kullanım oranı > %10

---

## 11. Risk Analizi ve Yönetim Stratejileri

### 11.1 Risk Matrisi

| Risk | Kategori | Olasılık | Etki | Öncelik | Azaltma Stratejisi |
|---|---|---|---|---|---|
| Güçlü rakipten agresif tepki | Rekabet | Yüksek | Yüksek | KRİTİK | Niş segmente odaklan; AI + güven farklılaşması |
| DSA / GDPR yaptırım | Hukuki | Orta | Kritik | KRİTİK | Day-1 uyum; Hollanda hukuk danışmanı |
| Kullanıcı güveni inşasında gecikme | Ürün | Orta | Yüksek | YÜKSEK | Progressive KYC + escrow erken devreye |
| Teknik ölçeklenebilirlik sorunları | Teknoloji | Orta | Yüksek | YÜKSEK | Load test, CDC pipeline, auto-scaling |
| Ödeme dolandırıcılığı | Güvenlik | Yüksek | Orta | YÜKSEK | AI + kural hibrit, escrow, KYC, siber sigorta |
| Veri ihlali | Güvenlik | Düşük | Kritik | YÜKSEK | Pentest, WAF, şifreleme, AP bildirimi SOP |
| Ekip tükenmişliği (3 kişi) | İK | Orta | Yüksek | ORTA | Net iş bölümü, 3. ayda işe alım |
| Nakit akışı / burn rate | Finansal | Orta | Orta | ORTA | 18 ay runway; erken escrow geliri |
| AI model drift | AI/ML | Orta | Orta | ORTA | Evidently drift tespiti, haftalık yeniden eğitim |
| CDC pipeline kesintisi (arama stale) | Teknoloji | Orta | Orta | ORTA | Kafka replication factor 3; lag alerting *(v3.0)* |
| Webhook kayıpları (ödeme olayı) | Teknoloji | Düşük | Kritik | YÜKSEK | Idempotency + retry + DLQ *(v3.0)* |

---

## 12. Kritik Başarı Faktörleri (KSF)

| KSF | Açıklama | Metrik | Hedef |
|---|---|---|---|
| KSF 1: İki Taraflı Pazar | Alıcı ve satıcı arzını dengeli büyütmek | İlan/Aktif Kullanıcı oranı | > 0,5 |
| KSF 2: Güven | Progressive KYC + escrow + düşük dolandırıcılık | Şikayet/işlem oranı | < %0,3 |
| KSF 3: Mobil Deneyim | Universal Links + uygulama hızı | App Store puanı | ≥ 4,3/5 |
| KSF 4: Organik Büyüme (SEO) | Programatik sayfalar + hreflang | Organik trafik payı | > %50 |
| KSF 5: AI Değer Yaratması | Öneriler + fiyat tahmini | Öneri CTR | > %15 |
| KSF 6: Arama Kalitesi | NL analyzer + CDC lag < 500ms | Arama sonuç alaka oranı | > %85 |
| KSF 7: Moderasyon | DSA ihbar SLA | İhbar yanıt süresi | < 24 saat |
| KSF 8: Kargo | PostNL/DHL entegrasyonu | Kargo kullanım oranı | > %40 |
| KSF 9: Likidite | İlanlar hızlı satılıyor | Ort. satış günü | < 14 gün |
| KSF 10: SLO Uyumu | Güvenilirlik | Error budget tüketimi | < %30/ay |
| KSF 11: ASO | App Store görünürlüğü *(v3.0)* | Organik yükleme oranı | > %40 |

### 12.1 ASO (App Store Optimization) Stratejisi *(v3.0 Yeni)*

v2.0'da hiç yer almıyordu. Mobil kullanıcı oranı %60+ olan bir platformda ASO kritik bir büyüme motorudur.

**App Store (iOS):**
- Başlık (30 karakter): "DeelMarkt — Koop & Verkoop"
- Alt Başlık (30 karakter): "Veilig tweedehands markt"
- Anahtar Kelimeler: tweedehands, kopen, verkopen, marktplaats alternatief, spullen
- Ekran Görüntüleri: 6,7" ve 6,1" için optimize; ürün güveni ve AI özellikleri öne çıkar
- İnceleme Yanıt Süresi: < 24 saat (App Store sıralamasını etkiler)

**Google Play (Android):**
- Kısa Açıklama (80 karakter): "Koop en verkoop veilig met escrow-beveiliging"
- Uzun Açıklama: anahtar kelime yoğunluğu %2–3; structured data
- A/B Testi: Google Play Store Listing Experiments ile icon + screenshot testi

---

## 13. Proje Yol Haritası ve Zaman Planlaması

### 13.1 Faz 0 — Hazırlık (1–4. Hafta)

| Hafta | Aktivite | Sorumlu | Çıktı |
|---|---|---|---|
| Hf. 1–2 | 50 kullanıcı görüşmesi, Jobs-to-be-Done analizi | CMO + CEO | Araştırma raporu |
| Hf. 1–2 | ADR yazımı, teknoloji kararları, CDC + Kafka tasarımı | CTO | Dev ortamı + Kafka cluster hazır |
| Hf. 2–3 | UX wireframe + WCAG 2.2 uyum kontrolü | UX + CTO | Test edilmiş prototip |
| Hf. 3–4 | Holding B.V. + Operations B.V. tescili | CEO + avukat | Hukuki yapı |
| Hf. 3–4 | Mollie + Onfido + PostNL + Cloudflare anlaşmaları | CEO + CTO | API erişimi + domain routing |
| Hf. 4 | OKR planlaması, sprint yapısı, ASO varlık üretimi başlangıcı | Tüm ekip | Sprint 1 hazır |

### 13.2 Faz 1 — MVP (1–6. Ay)

| Ay | Milestone | Temel Deliverable'lar |
|---|---|---|
| Ay 1–2 | Temel altyapı + kimlik | Next.js + NestJS, PostgreSQL + PgBouncer, iDIN, Unleash, Cloudflare routing |
| Ay 2–3 | İlan + arama sistemi | İlan CRUD, ES dutch analyzer, S3 + image pipeline, CDC (Debezium + Kafka) |
| Ay 3–4 | Mesajlaşma + escrow | WebSocket chat, Mollie escrow + double-entry ledger, webhook idempotency |
| Ay 4–5 | Güven + DSA katmanı | Progressive KYC, AI sahte ilan tespiti, Universal Links, DSA şeffaflık modülü |
| Ay 5–6 | Beta + güvenilirlik | 250 beta kullanıcı, SLO izleme, restore drill, penetrasyon testi |

### 13.3 Faz 2 — Büyüme (7–18. Ay)

| Dönem | Hedef | Temel Aktiviteler |
|---|---|---|
| Ay 7–9 | Public Launch + 50K kullanıcı | Lansman, referral, SEO, ASO, PR |
| Ay 9–12 | AI Özellikleri | Fiyat öneri, görsel arama, MLflow pipeline |
| Ay 12–15 | Monetizasyon olgunlaşması | Premium abonelik, reklam, canary deployment |
| Ay 15–18 | Benelux Hazırlığı | Belçika araştırması, Fransızca dil paketi, BNPL |

### 13.4 Faz 3 — Ölçeklendirme (18–36. Ay)

- Belçika (Operations BV) ve Almanya (GmbH) pazar girişleri
- Seri A turu (hedef: 3–5 milyon Euro)
- Microservices geçişi: AI, Arama, Bildirim servisleri ayrılır
- Canlı müzayede motoru
- B2B API ekosistemi

---

## 14. Gelir Modeli ve Finansal Projeksiyon

### 14.1 Gelir Kaynakları

| Kanal | Açıklama | Faz |
|---|---|---|
| Escrow Komisyonu | İşlem başı %2,5 | Faz 1 |
| Kargo Komisyonu | Entegre etiket başı %7 | Faz 1 |
| Öne çıkarma / Boost | €1–€10/ilan | Faz 1 |
| Premium Satıcı Aboneliği | €15–€50/ay: sınırsız ilan, analytics | Faz 1 |
| Display Reklam | B2C satıcılar için sponsored listing | Faz 2 |
| Veri & Analytics | İşletmeler için pazar trend raporları | Faz 2 |
| BNPL Referans Komisyonu | Klarna/Afterpay yönlendirme | Faz 2 |
| B2B API Erişimi | Üçüncü taraf entegrasyon | Faz 3 |

### 14.2 Birim Ekonomisi

| Metrik | Hedef |
|---|---|
| CAC (Kullanıcı Edinim Maliyeti) | < €5 (organik ağırlıklı) |
| LTV (Yaşam Boyu Değer — 3 yıl) | > €35 |
| LTV/CAC Oranı | > 7x |
| Aylık Churn (Premium) | < %3 |
| Escrow İşlem Dönüşümü | > %30 işlem |

### 14.3 Finansal Projeksiyon (3 Yıl)

| Metrik | Yıl 1 | Yıl 2 | Yıl 3 |
|---|---|---|---|
| Aktif Kullanıcı | 100.000 | 750.000 | 3.000.000 |
| Aylık Aktif İlan | 200.000 | 1.500.000 | 8.000.000 |
| Premium Satıcı | 2.000 | 15.000 | 60.000 |
| Aylık Escrow Hacmi | €500.000 | €5.000.000 | €25.000.000 |
| Toplam Yıllık Gelir | €600.000 | €3.500.000 | €15.000.000 |
| Personel Gideri | €450.000 | €1.200.000 | €4.000.000 |
| Altyapı / Teknoloji | €80.000 | €300.000 | €800.000 |
| Pazarlama Gideri | €150.000 | €600.000 | €2.000.000 |
| Hukuki / Uyum | €40.000 | €80.000 | €150.000 |
| EBITDA | −€120.000 | +€1.320.000 | +€8.050.000 |

### 14.4 Nakit Akışı ve Runway

| Metrik | Değer |
|---|---|
| Tahmini Başlangıç Sermayesi | €300.000 (bootstrap) |
| Aylık Burn Rate (Faz 1) | €55.000 |
| Burn Rate (Faz 2 başlangıç) | €90.000 |
| Tahmini Runway | 18 ay |
| Break-even Ayı | Ay 14 (tahmini) |
| Faz 2 Yatırım İhtiyacı (Seed) | €1,5M – €3M |

> **Kötümser Senaryo:** Kullanıcı edinim %50 yavaş ilerlerse break-even Ay 20'ye kayar; ek €600K sermaye gerekir. Faz 2 yatırım turunu Ay 9'da başlatın.

---

## 15. Mimari Karar Kayıtları (ADR)

| ADR | Karar | Gerekçe | Trade-off |
|---|---|---|---|
| ADR-001 | Modüler Monolit | 3 kişilik ekip; erken microservices yük | Faz 2'de refactor |
| ADR-002 | EventStoreDB + Double-Entry Ledger | PSD2 + DSA immutable audit + finansal denetim | Karmaşıklık artışı |
| ADR-003 | Mollie | iDEAL %69 pay; NL merkezli; native iDEAL | Stripe global ekosistemi yok |
| ADR-004 | Elasticsearch + Dutch Analyzer | 100M+ ilan; NL dil kalitesi kritik | Operasyonel karmaşıklık |
| ADR-005 | Feature Flags (Unleash) | Sıfır-downtime deploy; anında rollback | Her özellik için flag overhead |
| ADR-006 | OpenTelemetry | Vendor-agnostic distributed tracing | Ekstra soyutlama katmanı |
| ADR-007 | Debezium + Kafka CDC | Dual-write sorununu ortadan kaldır; ES tutarlılığı | Kafka operasyonel yük *(v3.0)* |
| ADR-008 | Outbox Pattern | DB write + event emit atomik olmalı | Outbox tablosu polling yükü *(v3.0)* |
| ADR-009 | Transaction mode PgBouncer | NestJS async context uyumu; bağlantı verimliliği | Session mode özelliklerinden vazgeçildi *(v3.0)* |
| ADR-010 | Progressive KYC | Kayıt sürtüşmesini minimize et; Amazon modeli | Geç KYC'de fraud penceresi *(v3.0)* |
| ADR-011 | Holding B.V. + Operations B.V. | IP optimizasyonu; uluslararası genişleme hazırlığı | Hukuki kurulum maliyeti *(v3.0)* |
| ADR-012 | deelmarkt.eu (primer) + .com (global) | .eu → AB güveni; .com → expat/küresel | İki domain yönetimi *(v3.0)* |

---

## 16. Sonuç ve Stratejik Öneriler

DeelMarkt projesi teknik açıdan uygulanabilir, pazar açısından zamanlı ve ekip yetkinlikleri açısından gerçekçi bir girişimdir. "Deel wat je hebt" — sahip olduklarını paylaş — sadece bir tagline değil, platformun DNA'sıdır.

Bu v3.0 raporu, v2.0'ın üzerine 15 yeni üretim kalitesi boşluğunu kapatan kapsamlı bir plan sunmaktadır.

### 16.1 Öncelikli Stratejik Adımlar

1. **Trust-first MVP:** Progressive KYC + escrow + double-entry ledger. Güven, uzun vadeli büyümenin temeli.
2. **CDC pipeline Faz 0'da kur:** Debezium + Kafka kurulumu gecikmesi, Elasticsearch tutarsızlıklarına yol açar.
3. **Webhook idempotency Day 1:** Mollie webhook'larını iş başlangıcından itibaren idempotent yap. Sonradan eklemek çok pahalıdır.
4. **DSA uyumunu Day 1'den kur:** Şeffaflık modülü MVP kapsamında.
5. **Progressive KYC:** Tam KYC'yi kayıt anında zorunlu kılma. Eşik bazlı yaklaşım kullanıcı kaybını minimize eder.
6. **Universal Links kurulumu:** MVP lansmanından önce tamamla. Bildirim → uygulama akışı dönüşüm için kritik.
7. **Holding yapısını şimdi kur:** BV'yi sonradan holding'e dönüştürmek vergi ve hukuki maliyeti yüksektir.
8. **Faz 2 yatırım turunu Ay 9'da başlat:** Ay 12'yi bekleme.

### 16.2 3 Kişilik Ekip İçin Kritik Disiplin

- **Kapsam kısıtlama:** Her sprint sonunda "neyi yapMAYacağız?" sorusu
- **Dış kaynak:** Tasarım, hukuk, vergi, ASO metinleri → serbest çalışanlar
- **No-code/low-code:** Moderasyon paneli, landing page → Retool/Webflow
- **Otomasyon:** Manuel tekrarlayan her görev otomasyon adayı
- **ADR kültürü:** Her önemli karar yazılır; bilgi tek kişiye bağlı olmamalı

> **Final:** DeelMarkt ismi "Deel" (paylaş/anlaşma) + "Markt" (pazar) kombinasyonuyla hem NL yerel kullanıcısına hem uluslararası expat kitlesine mükemmel hitap ediyor. .com ve .eu domainleri güvende. 6 ay içinde MVP'ye, Ay 14'te break-even'a, 18 ay içinde finansal sürdürülebilirliğe ulaşmak gerçekçidir.

---

## 17. Tier-1 Audit v2.0 — Kapatılan Bulgular (Özet)

| # | Bulgu | Seviye | Çözüm |
|---|---|---|---|
| A-01 | EventStoreDB yok — PSD2 immutable audit trail | Kritik | ADR-002 + §5.7 |
| A-02 | DSA uyum modülü eksik | Kritik | §6.3 + MVP P1 |
| A-03 | Gizli yönetimi yok | Kritik | AWS Secrets Manager |
| A-04 | SLO/SLI/Error Budget yok | Yüksek | §7.2 |
| A-05 | Feature flag sistemi yok | Yüksek | Unleash + ADR-005 |
| A-06 | MLOps eksik | Yüksek | §8 |
| A-07 | Distributed tracing yok | Yüksek | OpenTelemetry + ADR-006 |
| A-08 | Veri ambarı (OLAP) yok | Yüksek | Redshift Serverless |
| A-09 | GDPR sağ-silme belirsiz | Yüksek | §5.4 veri sınıflandırması |
| A-10 | Dispute resolution iş akışı yok | Yüksek | §4.1 Katman 2 |
| A-11 | API versiyonlama politikası yok | Orta | §5.5 |
| A-12 | Rate limiting tanımsız | Orta | §5.5 Kong tablosu |
| A-13 | OWASP Top 10 planı yok | Orta | §6.1 |
| A-14 | Incident management yok | Orta | §7.4 |
| A-15 | DR RTO/RPO belirsiz | Orta | §7.5 |
| A-16 | Push notification stratejisi yok | Düşük | §4.2 MVP tablosu |
| A-17 | Nakit akışı / runway analizi eksik | Düşük | §14.4 |
| A-18 | BNPL göz ardı edilmişti | Düşük | §14.1 |

---

## 18. Tier-1 Audit v3.0 — Yeni Bulgular ve Revizyonlar

Bu bölüm, v3.0 Senior Staff Engineer değerlendirmesindeki 15 yeni bulguyu ve uygulamalarını belgeler.

### 18.1 Kritik Bulgular (v3.0)

| # | Bulgu | Seviye | Çözüm |
|---|---|---|---|
| B-01 | CDC-based search indexing yok — dual-write veri tutarsızlığı riski | Kritik | Debezium + Kafka CDC §5.5 + ADR-007 |
| B-02 | Escrow double-entry accounting ledger yok — PSD2 finansal denetim uyumsuzluğu | Kritik | Double-entry ledger §5.7 + ADR-002 güncellemesi |
| B-03 | Mollie webhook idempotency + retry yok — ödeme olayı kayıp / duplikasyon riski | Kritik | Idempotency + exponential backoff §5.8 |

### 18.2 Yüksek Öncelikli Bulgular (v3.0)

| # | Bulgu | Seviye | Çözüm |
|---|---|---|---|
| B-04 | Dutch language Elasticsearch analyzer yok — NL arama kalitesi düşük | Yüksek | `dutch` analyzer konfigürasyonu §5.4 + ADR-004 güncellemesi |
| B-05 | Cache invalidation stratejisi yok — satılmış ilanlar cache'de görünür | Yüksek | Event-driven invalidation tablosu §5.6 |
| B-06 | Outbox pattern yok — DB write + event emit atomik değil | Yüksek | Outbox table + poller §4.1 + ADR-008 |
| B-07 | Universal Links / App Links yok — mobil dönüşüm kaybı | Yüksek | Branch.io + native impl. §5.12 |
| B-08 | Multi-domain routing stratejisi yok — .com ve .eu çakışma riski, SEO sorunu | Yüksek | Cloudflare geo-routing + hreflang §5.11 |
| B-09 | PgBouncer konfigürasyonu eksik — wrong pool_mode production'da bağlantı tüketimi | Yüksek | Transaction mode + parametreler §5.10 |

### 18.3 Orta Öncelikli Bulgular (v3.0)

| # | Bulgu | Seviye | Çözüm |
|---|---|---|---|
| B-10 | WCAG 2.1 → 2.2 yükseltmesi yapılmamış (Ekim 2023'ten beri güncel standart 2.2) | Orta | §9.3 WCAG 2.2 yeni kriterler |
| B-11 | Image processing pipeline tanımsız — max boyut, format, WebP/AVIF, EXIF stripping yok | Orta | Lambda (Sharp) pipeline §5.9 |
| B-12 | Progressive KYC yok — tam KYC kayıtta yüksek sürtüşme, kullanıcı kaybı | Orta | Eşik bazlı KYC tablosu §6.5 + ADR-010 |
| B-13 | ASO stratejisi tamamen yok — mobil organik büyüme körleşiyor | Orta | §12.1 ASO stratejisi |
| B-14 | Hukuki yapı tek BV — uluslararası genişlemede vergi ve IP riski | Orta | Holding + Operations yapısı §10.2 + ADR-011 |
| B-15 | Database restore drill yok — "test edilmemiş yedek, yedek değildir" | Orta | Aylık otomatik restore test §7.5 |

### 18.4 v2.0 → v3.0 Mimari Karşılaştırması

| Alan | v2.0 | v3.0 (Bu Belge) |
|---|---|---|
| Arama senkronizasyonu | "Elasticsearch var" | Debezium + Kafka CDC; < 500ms lag SLO |
| Ödeme denetimi | EventStoreDB (event log) | EventStoreDB + Double-entry ledger + reconciliation job |
| Webhook güvenilirliği | "Mollie entegrasyonu" | Idempotency + exponential backoff + DLQ + alerting |
| NL arama kalitesi | Varsayılan ES analyzer | `dutch` analyzer + stemming + compound word decompositon |
| Cache | Redis cluster | Redis + event-driven invalidation stratejisi |
| KYC | "Onfido entegrasyonu" | Progressive 5-seviyeli KYC; eşik bazlı |
| Mobile | React Native | + Universal Links + App Links + ASO stratejisi |
| Multi-domain | "pikko.nl" (tek domain) | deelmarkt.eu + .com; Cloudflare geo-routing; hreflang |
| Veritabanı bağlantısı | "PgBouncer var" | Transaction mode; pool_size=20; max_client_conn=200 |
| Erişilebilirlik | WCAG 2.1 AA | WCAG 2.2 AA; 5 yeni kriter |
| Hukuki yapı | Hollanda BV | Holding B.V. + Operations B.V. + genişleme yapısı |
| Yedekleme | Yedekler alınıyor | + Aylık otomatik restore drill + Slack raporu |

---

*© 2025 DeelMarkt — deelmarkt.com | deelmarkt.eu | Proje Ekibi | Tüm Hakları Saklıdır | GİZLİ — v3.0*
