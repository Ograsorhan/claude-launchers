# Claude Launchers — Windows için kolay kurulum

Claude Code arayüzünü yerel Ollama modelleri veya FreeLLMAPI üzerinden kullanın. Varsayılan kurulum yerel modeli hazırlar; kod veya ayar dosyası düzenlemeniz gerekmez.

## İndir ve başlat

1. [Windows kurulum ZIP dosyasını indir](https://github.com/Ograsorhan/claude-launchers/releases/latest/download/Claude-Launchers-Windows.zip).
2. ZIP'e sağ tıklayıp **Tümünü ayıkla** seçeneğini kullanın.
3. Çıkan klasörde **KUR.cmd** dosyasına çift tıklayın.
4. Ekrandaki Windows/lisans onaylarını tamamlayın ve indirmelerin bitmesini bekleyin.
5. Kurulumdan sonra masaüstündeki **Claude Launchers** kısayolunu açın.

İlk kurulum Claude Code, Ollama ve belge okumak için Python/pypdf bileşenlerinin eksik olanlarını kurar. Qwen 3.5 4B modelini indirir, ayrı bir 64K bağlamlı yerel model oluşturur ve model/Claude bağlantısını sınar. Tekrar çalıştırıldığında mevcut kurulumları kullanır, başarısız adımlar yeniden denenebilir. Model indirme boyutu birkaç GB'tır ve bilgisayara göre uzun sürebilir.

Release henüz oluşmadıysa **Code → Download ZIP** ile kaynakları indirip aynı adımları uygulayabilirsiniz.

## Gereksinimler

- Windows 10/11 **x64**, PowerShell 5.1 ve WinGet (Microsoft App Installer).
- İlk kurulumda internet ve model/programlar için yeterli disk alanı.
- Yerel modelin hızı ve açılabilmesi RAM/VRAM'e bağlıdır. 16 GB veya daha fazla RAM pratik bir başlangıç önerisidir; 64K bağlam bazı sistemlerde daha fazla bellek isteyebilir. Her bilgisayarda aynı performans garanti edilmez.
- Windows izin veya uygulama lisans ekranları açabilir. Kurulum bu onayları otomatik kabul etmez; güvenlik uyarılarını kapatmaz.

Daha küçük model isteyenler PowerShell'de `./KUR.cmd -Model qwen3.5:2b` çalıştırabilir. Bu modelin kodlama ve araç kullanma yeteneği daha sınırlı olabilir.

## Bulut / FreeLLMAPI

**KUR-BULUT.cmd** dosyasını açın. Kurucu FreeLLMAPI 0.15.0 Windows paketini resmi GitHub sürümünden indirir, yayınlanmış SHA256 değerini doğrular ve çıkarır. Uygulamanın **Keys** bölümünde kendi sağlayıcı hesabınızı/anahtarınızı ekleyip kurulum penceresinde Enter'a basın. Hazır ve anahtarsız bir bulut hesabı sağlanmaz. Varsayılan yönlendirme `auto` kullanır; önceki bilgisayarın özel model zincirine bağımlı değildir.

Yerel ve bulut kısayolu, en son başarıyla tamamlanan kurulumun modunu açar. İlgili KUR dosyasını yeniden çalıştırarak değiştirebilirsiniz. Ayrı başlatıcılar `Yerel-Hizli-Claude.cmd`, `FreeLLMAPI-Claude.cmd` ve `FreeLLMAPI-Claude-Devam.cmd` de kullanılabilir.

Bulut istemleri seçtiğiniz sağlayıcılara gider; kota, ücret ve koşullar sağlayıcıya aittir. Bu paket Anthropic Claude modelini veya aboneliğini ücretsiz sağlamaz; Claude Code istemcisi farklı modellerle çalışır.

## Dosyalar ve kaldırma

- Uygulama: `%LOCALAPPDATA%\ClaudeLaunchers\app`
- Varsayılan çalışma klasörü: Belgeler altında `Claude Projeleri`.
- Ayarlar: uygulama klasöründeki `launcher-config.json`. Anahtar içermez; Git'e eklenmez.
- Başlatıcı anahtarları çalışma sırasında yerel servisten alır, oturuma özel ayar dosyasını normal kapanışta temizler. Zorla kapatılan oturumlarda `%LOCALAPPDATA%\ClaudeLaunchers\sessions` altında artık dosya kalabilir.
- Claude'un kullanıcı onayları korunur. Kendi Claude oturum/ayar dosyalarınız değiştirilemez; bu başlatıcı yalnızca kendi ayar dosyasını kullanır.

Kaldırmak için kısayolları ve `%LOCALAPPDATA%\ClaudeLaunchers` klasörünü silebilirsiniz. Projeleriniz, Claude Code, Ollama, Python, FreeLLMAPI sağlayıcı verileri ve indirilen Ollama modelleri ayrı kalır. Bunları kendi uygulamalarından kaldırabilirsiniz.

## Doğrulama ve sınırlar

Windows PowerShell 5.1 altında `tests/Test-Package.ps1` ile sözdizimi, ayar okuma, boşluklu yollar, argüman aktarımı, hata kodları ve geçici dosya temizliği sınanır. `Kur.ps1 -Plan` hiçbir kurulum yapmadan planı gösterir. GitHub Actions aynı kontrolleri çalıştırır ve ZIP paketini üretir. Kurucu başarı bildirmeden önce gerçek model ve Claude Code bağlantısını kontrol eder.

Temiz bir Windows bilgisayarda tüm programların sıfırdan kurulumu henüz uçtan uca doğrulanmadı. Uygulama sürümleri ve model uyumluluğu değişebilir. Hata olursa kurulum penceresi nedeni gösterir; pencereyi kapatmadan hata metnini paylaşın. Taranmış belgeler için OCR dahil değildir.

Resmi kaynaklar: [Claude Code kurulumu](https://code.claude.com/docs/en/setup), [Ollama ve Claude Code](https://docs.ollama.com/integrations/claude-code), [Qwen 3.5 4B](https://ollama.com/library/qwen3.5:4b), [FreeLLMAPI sürümleri](https://github.com/tashfeenahmed/freellmapi/releases/tag/v0.15.0).
