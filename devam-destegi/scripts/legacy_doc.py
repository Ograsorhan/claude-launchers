"""Read main-story text from unencrypted Word 97+ DOC; no Office automation."""
# Format reference: Microsoft MS-DOC (FibRgFcLcb97, Clx, PlcPcd, FcCompressed).
# https://learn.microsoft.com/en-us/openspecs/office_file_formats/ms-doc/
import struct

def u16(b,p): return struct.unpack_from('<H',b,p)[0]
def u32(b,p): return struct.unpack_from('<I',b,p)[0]

class Compound:
    def __init__(self,data):
        self.data=data
        if data[:8]!=bytes.fromhex('d0cf11e0a1b11ae1'): raise ValueError('DOC bilesik dosya imzasi yok.')
        self.sector=1<<u16(data,30); self.mini=1<<u16(data,32)
        if self.sector not in (512,4096) or self.mini!=64: raise ValueError('Desteklenmeyen DOC sektor bicimi.')
        difat=[u32(data,76+i*4) for i in range(109)]
        sid=u32(data,68); seen=set()
        for _ in range(min(u32(data,72),len(data)//self.sector)):
            if sid in seen: raise ValueError('Bozuk DIFAT zinciri.')
            seen.add(sid); b=self.block(sid)
            difat.extend(u32(b,i) for i in range(0,self.sector-4,4));sid=u32(b,self.sector-4)
        self.fat=[]
        for sid in [x for x in difat if x<0xfffffffa][:u32(data,44)]:
            b=self.block(sid); self.fat.extend(struct.unpack('<'+'I'*(len(b)//4),b))
        directory=self.chain(u32(data,48),self.fat,self.block)
        self.entries={};root=None
        for i in range(0,len(directory)-127,128):
            e=directory[i:i+128];n=u16(e,64)
            if n<2 or n>64: continue
            name=e[:n-2].decode('utf-16le');item=(u32(e,116),struct.unpack_from('<Q',e,120)[0])
            if e[66]==5: root=item
            elif e[66]==2: self.entries[name]=item
        self.minifat=[];self.ministream=b''
        if root:
            self.ministream=self.chain(root[0],self.fat,self.block)[:root[1]]
        if u32(data,64):
            b=self.chain(u32(data,60),self.fat,self.block)
            self.minifat=list(struct.unpack('<'+'I'*(len(b)//4),b))
        self.cutoff=u32(data,56)
    def block(self,sid):
        start=(sid+1)*self.sector
        if sid>=0xfffffffa or start+self.sector>len(self.data): raise ValueError('Gecersiz DOC sektor konumu.')
        return self.data[start:start+self.sector]
    def chain(self,sid,fat,get):
        out=[];seen=set()
        while sid!=0xfffffffe:
            if sid in seen or sid>=len(fat): raise ValueError('Bozuk DOC akis zinciri.')
            seen.add(sid);out.append(get(sid));sid=fat[sid]
        return b''.join(out)
    def stream(self,name):
        if name not in self.entries: raise ValueError('Gerekli DOC akisi yok: '+name)
        sid,size=self.entries[name]
        if not size:return b''
        if size<self.cutoff:
            def get(i):
                b=self.ministream[i*self.mini:(i+1)*self.mini]
                if len(b)!=self.mini:raise ValueError('Bozuk DOC mini sektor.')
                return b
            return self.chain(sid,self.minifat,get)[:size]
        return self.chain(sid,self.fat,self.block)[:size]

def read_doc(path):
    c=Compound(path.read_bytes());w=c.stream('WordDocument')
    if u16(w,0)!=0xa5ec or u16(w,2)<0xc1:raise ValueError('Yalniz Word 97 ve sonrasi DOC destekleniyor.')
    flags=u16(w,10)
    if flags&0x8100:raise ValueError('Sifreli/korumali DOC desteklenmiyor.')
    table=c.stream('1Table' if flags&0x200 else '0Table')
    p=32;csw=u16(w,p);p+=2+2*csw;cslw=u16(w,p);p+=2
    count=u32(w,p+12);p+=4*cslw
    pairs=u16(w,p);p+=2
    if pairs<=33:raise ValueError('DOC metin parca tablosu yok.')
    start,length=u32(w,p+33*8),u32(w,p+33*8+4)
    clx=table[start:start+length];i=0
    while i<len(clx) and clx[i]==1:i+=3+u16(clx,i+1)
    if i>=len(clx) or clx[i]!=2:raise ValueError('DOC CLX metin tablosu okunamadi.')
    size=u32(clx,i+1);plc=clx[i+5:i+5+size]
    if len(plc)!=size or size<4 or (size-4)%12:raise ValueError('Bozuk DOC parca tablosu.')
    n=(size-4)//12;out=[]
    for k in range(n):
        a,b=u32(plc,k*4),u32(plc,(k+1)*4)
        if b<a:raise ValueError('Bozuk DOC karakter araligi.')
        if a>=count:break
        chars=min(b,count)-a;fc=u32(plc,4*(n+1)+8*k+2)
        compressed=bool(fc&0x40000000);pos=fc&0x3fffffff
        if compressed:pos//=2
        raw=w[pos:pos+chars*(1 if compressed else 2)]
        if len(raw)!=chars*(1 if compressed else 2):raise ValueError('Eksik DOC metni.')
        out.append(raw.decode('cp1252' if compressed else 'utf-16le',errors='replace'))
    text=''.join(out).replace('\r','\n').replace('\x07','\t').replace('\x0b','\n').replace('\x0c','\n')
    if not text.strip():raise ValueError('DOC ana metni bulunamadi.')
    return text
