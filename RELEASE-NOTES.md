## v0.2.2 — Davranış ve düşünme ayarı düzeltmesi

- Eylem isteklerinde gerçek araç kullanımı, işi test ederek bitirme, aynı plan/onayı tekrarlamama ve kısa sonuç bildirme kuralları eklendi.
- Bulut modunda düşünme açıldı; 4096 düşünme / 8192 çıktı token bütçesi ayarlandı. Eski kapatma değeri geçersiz kılınır.
- Kullanıcının model kataloğunda varsa ücretsiz Nemotron 3.5 Super VL tercih edilir. Yoksa auto yönlendirmesi; açıkça seçilmiş bir model varsa kullanıcının seçimi korunur.
- Yerel modelin performans ayarları korunur. API anahtarları veya kişisel model zincirleri paylaşılmaz.

Yeni kurulum: ZIP'i tamamen çıkarıp KUR.cmd (yerel) veya KUR-BULUT.cmd (bulut) dosyasını çalıştırın. Bulut sağlayıcı hesabını kullanıcı kendisi yapılandırır.

Güncelleme: Kullandığınız kurulum dosyasını yeni ZIP klasöründen yeniden çalıştırın, sonra açık Claude penceresini kapatıp kısayoldan tekrar açın. Mevcut launcher-config.json korunur.

Kontroller: Windows PowerShell 5.1 paket testleri, model tercihi/yedek yönlendirme, düşünme ayarları, hata kodları ve geçici dosya temizliği. Geliştirme bilgisayarındaki Nemotron dosya okuma/düzeltme/komut testi 6/6 geçti. Temiz Windows kurulumu ve her sağlayıcı hesabı uçtan uca denenmedi; model hataları ve kota sınırları sürebilir.
