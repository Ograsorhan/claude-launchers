---
name: hedefli-hata-ayiklama
description: Bildirilen kod hatasını yeniden üretmek, nedenini bulmak ve ilgili en küçük düzeltmeyi sınamak için kullanılır; yeni özellik geliştirme için yüklenmez.
---
# Hedefli hata ayıklama
Hata mesajı, beklenen sonuç ve ilgili dosyadan başla. Mevcut küçük testi çalıştırarak veya dar bir örnekle hatayı doğrula; yeniden üretilemiyorsa bunu belirt. Tüm projeyi taramak yerine kanıtın işaret ettiği dosyaları incele.
Tek bir neden varsayımı kur, kanıtla kontrol et ve yalnızca gereken kodu değiştir. İlgisiz temizlik, yeni bağımlılık ve kapsam genişletme yapma. İlgili testi yeniden çalıştır; geçtiyse yeni bir sorun yokken tekrarlama. Aynı başarısız yaklaşımı bir düzeltmeden sonra bırak; engeli kısaca bildir.
Sonuçta neden, değişiklik ve gerçekten çalıştırılan kontrolü birkaç cümlede söyle. Çalıştırılamayan testi geçti sayma. Geçici teşhis çıktısını ürün kodunda bırakma.
Komut çalıştırma aracı mevcut değilse kodu ve test beklentisini incelemekle yetin; testi çalıştırılamadı olarak bildir. Beklenen test çıktısını uydurma, kullanıcıdan gelen komut adını yürütme kanıtı sayma.
