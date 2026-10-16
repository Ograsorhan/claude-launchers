# Claude Code başlatıcıları (Windows)

Claude Code istemcisini FreeLLMAPI veya yerel Ollama modellerine bağlamak için PowerShell ve CMD başlatıcıları. Bu depo Claude Code veya model ağırlıklarını içermez. Kullanılan modeller Anthropic Claude modeli olmak zorunda değildir.

## Gereksinimler

- Windows ve PowerShell.
- Claude Code: `%USERPROFILE%\.local\bin\claude.exe`.
- Ollama: `http://127.0.0.1:11434`.
- Yerel sürüm için Ollama üzerinde `qwen3.5-hizli:4b` adlı modelin önceden hazırlanması gerekir. Bu ad yerel bir model takma adıdır; bu depoda model tanımı bulunmaz. Başka model kullanmak için `Yerel-Hizli-Claude.ps1` içindeki `$chain` değerini değiştirin.
- FreeLLMAPI sürümü için `http://127.0.0.1:31415` üzerinde çalışan FreeLLMAPI ve uygulamada önceden yapılandırılmış `auto:ucretsiz-gecis` zinciri gerekir. Sağlayıcı ve zincir ayarları bu depoya dahil değildir.
- Otomatik başlatma için `Hizmetleri-Hazirla.ps1` içindeki kurulum yollarını kendi bilgisayarınıza göre düzenleyin.

## Kullanım

Tüm dosyaları aynı klasör yapısıyla indirin.

- `Yerel-Hizli-Claude.cmd`: yerel Ollama modeliyle başlatır.
- `FreeLLMAPI-Claude.cmd`: FreeLLMAPI üzerinden başlatır.
- `FreeLLMAPI-Claude-Devam.cmd`: FreeLLMAPI ile önceki oturuma devam eder.

Komut satırı argümanları Claude Code'a iletilir. `Calisma-kurallari.md` ve `devam-destegi` klasörü başlatıcıların yanında bulunmalıdır. Belge okuma yardımcılarının ek gereksinimleri ilgili skill dosyalarında açıklanır.

## Kimlik bilgileri

FreeLLMAPI anahtarı çalışma sırasında yerel servisten alınır; depoda saklanmaz. Geçici Claude ayar dosyası kapanışta temizlenir. Kendi API anahtarlarınızı, oturum dosyalarınızı ve kişisel belgelerinizi Git'e eklemeyin.

## Doğrulama

Paket hazırlanırken PowerShell dosyaları sözdizimi açısından kontrol edilmiştir. Bu paket bağımsız ve sıfırdan kurulum veya canlı servis testi olarak doğrulanmamıştır. Sağlayıcıların kota ve ücret koşulları kendilerine bağlıdır.
