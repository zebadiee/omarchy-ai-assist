package main
import(
 "encoding/json";"fmt";"log";"net/http";"os";"path/filepath";"time"
)
type Query struct{Q string`json:"q"`}
func logEvent(ev,info string){
 root:=os.Getenv("OMARCHY_ROOT")
 if root==""{h,_:=os.UserHomeDir();root=filepath.Join(h,".omarchy","current")}
 os.MkdirAll(filepath.Join(root,"logs"),0755)
 f,_:=os.OpenFile(filepath.Join(root,"logs","usage.jsonl"),os.O_APPEND|os.O_CREATE|os.O_WRONLY,0644)
 defer f.Close()
 fmt.Fprintf(f,"{\"time\":\"%s\",\"event\":\"%s\",\"info\":\"%s\"}\n",time.Now().UTC().Format(time.RFC3339),ev,info)
}
func main(){
 http.HandleFunc("/ping",func(w http.ResponseWriter,_ *http.Request){fmt.Fprint(w,"ok")})
 http.HandleFunc("/search",func(w http.ResponseWriter,r *http.Request){
  defer r.Body.Close()
  var q Query; _=json.NewDecoder(r.Body).Decode(&q)
  logEvent("search_query",q.Q)
  res:=map[string]any{"query":q.Q,"results":[]map[string]any{{"id":"demo","score":0.42,"snippet":"hello R&D"}}}
  w.Header().Set("Content-Type","application/json");json.NewEncoder(w).Encode(res)
 })
 addr:=":8188";log.Printf("🔎 searchd live %s",addr);log.Fatal(http.ListenAndServe(addr,nil))
}
