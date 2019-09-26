# fast-lzma2-delphi
fast-lzma2.h conversion to delphi.
It's not completed yet. Let me know if you can contribute with the conversion too.
You need fast-lzma2.dll to use this.

A simple example:

var
  ms: tmemorystream;
  outbuff: pointer;
  outsize: integer;
  outa: TFileStream;

begin
  try
   ms := tmemorystream.Create;
	 
  ms.LoadFromFile(Paramstr(1)); {Loading file to memory}
	
  getmem(outbuff, ms.Size + 14); {Getting required memory to buffer}
	
  outsize:=FL2_compressmt(outbuff,ms.Size+14,ms.Memory,ms.Size,9); {Compressing using fast lzma2}
	
  outa:=TFilestream.Create(Paramstr(2), fmCreate);
	
  outa.Writebuffer(outbuff^, outsize); {Writting to output}
	
  outa.free;
	
  ms.Free;
	
  except
	
    on E: Exception do
		
      Writeln(ErrOutput,E.ClassName + ': ' + E.Message);
			
  end;
	
end.

