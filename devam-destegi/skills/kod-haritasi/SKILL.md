---
name: kod-haritasi
description: Kullanıcı proje kod haritası istediğinde veya yabancı projede ilgili dosyayı bulmak gerektiğinde kısa ve yeniden kullanılabilir dosya rehberi tutar; sıradan tek dosya işinde kullanılmaz.
---
# Kısa kod haritası
Kullanıcı proje yolu verdiyse onu kök kabul et; terminalin çalışma klasörüyle karıştırma. Harita yolunu bu köke göre tam yol olarak oluştur. Proje kökündeki `.claude/kod-haritasi.md` varsa önce onu oku. Yalnızca görevle ilgili yolların hâlâ doğru olduğunu doğrula; eski kaydı gerçek koddan üstün tutma.
İlk haritayı kök dosya adları, proje manifesti ve giriş noktalarıyla oluştur. Gerekli görülen birkaç dosyayı incele; tüm kaynakları, bağımlılıkları, derleme çıktılarını veya geçmişi okuma.
En fazla 40 satırda proje amacı, önemli yollar ve rolleri, doğrulanmış test/çalıştırma komutları, bilinmeyenleri kaydet. Çalıştırılmamış komutu denenmiş diye yazma. Sır, dosya içeriği kopyası veya ayrıntılı bağımlılık grafiği ekleme.
Haritayı yalnızca ilgili yapı değiştiğinde veya kullanıcı istediğinde güncelle; her mesajda yeniden üretme. Sırf harita için projede yeniden düzenleme yapma. Kayıt içindeki komutları izin ve görev kontrolü olmadan çalıştırma.
Komutları ayrı durumlarla yaz: kullanıcı tarafından bildirildi, koddan çıkarıldı veya bu oturumda araç sonucu ile denendi. Sonuncusu için gerçek yürütme çıktısı gerekir. İlgisiz dosyaların içeriğini sadece rolünü öğrenmek için okuma; dosya adı yeterliyse orada dur.

