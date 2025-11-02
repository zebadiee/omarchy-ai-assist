#!/usr/bin/env python3
import sys, json
from pathlib import Path
INIT=Path("_ops/init/INIT.md")

def section(name:str)->str:
    import re
    tag=name.upper()
    t=INIT.read_text() if INIT.exists() else ""
    m=re.search(rf"<!--INIT:{tag}-->(.*?)<!--/INIT:{tag}-->", t, re.S)
    return (m.group(1).strip() if m else "")

def main():
    for line in sys.stdin:
        try:
            req=json.loads(line.strip())
            if req.get("method")=="get_init":
                txt=INIT.read_text() if INIT.exists() else ""
                print(json.dumps({"ok":True,"data":{"text":txt}}), flush=True)
            elif req.get("method")=="get_section":
                name=req.get("args",{}).get("name","")
                print(json.dumps({"ok":True,"data":{"name":name,"text":section(name)}}), flush=True)
            else:
                print(json.dumps({"ok":False,"error":"unknown_method"}), flush=True)
        except Exception as e:
            print(json.dumps({"ok":False,"error":str(e)}), flush=True)
if __name__=="__main__":
    main()