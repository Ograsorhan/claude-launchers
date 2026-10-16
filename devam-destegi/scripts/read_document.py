import argparse, json, re, sys, zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

def xml(z, name):
    info = z.getinfo(name)
    if info.file_size > 25_000_000:
        raise ValueError('Belge parcasi cok buyuk; daha kucuk bir belge kullanin.')
    return ET.fromstring(z.read(name))

def text_nodes(root, suffix='t'):
    return ' '.join(n.text or '' for n in root.iter() if n.tag.rsplit('}', 1)[-1] == suffix)

def extract(p, pages):
    ext = p.suffix.lower()
    if ext == '.doc':
        from legacy_doc import read_doc
        return read_doc(p)
    if ext == '.pdf':
        from pypdf import PdfReader
        r = PdfReader(p)
        if r.is_encrypted and not r.decrypt(''):
            raise ValueError('Sifreli PDF; sifresiz kopya gerekli.')
        result = '\n'.join('[Sayfa %d]\n%s' % (i+1, r.pages[i].extract_text() or '') for i in range(min(pages, len(r.pages))))
        return result or 'Metin bulunamadi; taranmis belge icin OCR gerekli.'
    if ext in ('.docx', '.xlsx', '.pptx', '.odt'):
        with zipfile.ZipFile(p) as z:
            names = z.namelist()
            if ext == '.docx':
                parts = ['word/document.xml'] + sorted(n for n in names if re.fullmatch(r'word/(?:header\d+|footer\d+|footnotes|endnotes)\.xml', n))
                lines = []
                for part in parts:
                    root = xml(z, part)
                    lines.extend(text_nodes(n) for n in root.iter() if n.tag.rsplit('}', 1)[-1] == 'p')
                return '\n'.join(lines)
            if ext == '.odt':
                root = xml(z, 'content.xml')
                return '\n'.join(''.join(n.itertext()) for n in root.iter() if n.tag.rsplit('}', 1)[-1] in ('p','h'))
            if ext == '.pptx':
                parts = sorted((n for n in names if re.fullmatch(r'ppt/slides/slide\d+\.xml',n)), key=lambda n:int(re.search(r'(\d+)\.xml',n)[1]))
                return '\n'.join('[Slayt %d]\n%s' % (i+1,text_nodes(xml(z,n))) for i,n in enumerate(parts[:pages]))
            shared = []
            if 'xl/sharedStrings.xml' in names:
                shared = [text_nodes(n) for n in xml(z,'xl/sharedStrings.xml')]
            lines = []
            parts = sorted(n for n in names if re.fullmatch(r'xl/worksheets/sheet\d+\.xml',n))
            for part in parts[:pages]:
                lines.append('['+part+']')
                for c in xml(z,part).iter():
                    if c.tag.rsplit('}',1)[-1] != 'c': continue
                    typ=c.get('t',''); value=''
                    for n in c:
                        tag=n.tag.rsplit('}',1)[-1]
                        if tag=='v': value=n.text or ''
                        elif tag=='is': value=text_nodes(n)
                        elif tag=='f': lines.append(c.get('r','')+' formula='+ (n.text or ''))
                    if typ=='s' and value: value=shared[int(value)]
                    lines.append(c.get('r','')+'='+value)
            return '\n'.join(lines)
    if ext == '.rtf':
        raise ValueError('RTF icin Read-Document.ps1 Word okuyucusunu kullanin.')
    allowed={'.txt','.md','.csv','.tsv','.json','.xml','.html','.htm','.log','.py','.js','.ts','.css','.yaml','.yml','.ini','.c','.cpp','.h','.sql','.ps1','.cjs','.mjs'}
    if ext not in allowed:
        raise ValueError('Bu bicim desteklenmiyor. Ikili dosyalar veya taranmis belgeler icin ayri okuyucu/OCR gerekli.')
    data=p.read_bytes()
    encodings = ('utf-16',) if data.startswith((b'\xff\xfe',b'\xfe\xff')) else ('utf-8-sig','cp1254')
    for enc in encodings:
        try: return data.decode(enc)
        except UnicodeError: pass
    raise ValueError('Metin kodlamasi okunamadi.')

def main():
    a=argparse.ArgumentParser(); a.add_argument('path'); a.add_argument('--max-chars',type=int,default=16000); a.add_argument('--offset',type=int,default=0); a.add_argument('--pages',type=int,default=20); args=a.parse_args()
    p=Path(args.path).resolve(strict=True)
    if not p.is_file() or p.stat().st_size>100_000_000: raise ValueError('Dosya yok, klasor veya 100 MB sinirini asiyor.')
    if not 1<=args.max_chars<=100000 or args.offset<0 or not 1<=args.pages<=500: raise ValueError('Gecersiz okuma siniri.')
    text=extract(p,args.pages)
    print(json.dumps({'path':str(p),'text':text[args.offset:args.offset+args.max_chars],'offset':args.offset,'total_chars':len(text),'truncated':len(text)>args.offset+args.max_chars,'page_limit':args.pages,'note':'Yalniz metin/cell degerleri; gorsel duzen, gomulu nesneler ve OCR dahil degil. Formuller calistirilmaz.'},ensure_ascii=False))

if __name__=='__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    try: main()
    except Exception as e:
        print(json.dumps({'error':str(e)},ensure_ascii=False)); sys.exit(1)
