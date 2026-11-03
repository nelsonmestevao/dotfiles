// Bounded, generation-safe read reuse. No host APIs and no cached writes.
export class ReadCache {
  constructor({ttl=400,maxEntries=32,maxValue=262144,clock=()=>Date.now()}={}) {
    Object.assign(this,{ttl,maxEntries,maxValue,clock});this.entries=new Map();
  }
  get size(){return this.entries.size;}
  invalidate(){this.entries.clear();}
  read(key,loader) {
    const cached=this.entries.get(key);
    if(cached && (cached.pending || cached.expires>this.clock())) {
      this.entries.delete(key);this.entries.set(key,cached);return cached.promise;
    }
    const entry={pending:true};this.entries.set(key,entry);
    while(this.entries.size>this.maxEntries)this.entries.delete(this.entries.keys().next().value);
    entry.promise=Promise.resolve().then(loader).then(value=>{
      if(this.entries.get(key)===entry){
        if(JSON.stringify(value)?.length>this.maxValue)this.entries.delete(key);
        else {entry.pending=false;entry.expires=this.clock()+this.ttl;}
      }
      return value;
    },error=>{if(this.entries.get(key)===entry)this.entries.delete(key);throw error;});
    return entry.promise;
  }
}
export class Coalescer {
  constructor(){this.ticket=0;this.pending=false;}
  request(schedule,work) {
    this.work=work;if(this.pending)return;
    this.pending=true;const ticket=++this.ticket;
    this.task=schedule(cx=>{if(ticket!==this.ticket)return;this.pending=false;this.task=null;this.work(cx);});
  }
  cancel(){this.ticket++;this.pending=false;this.task?.cancel();this.task=null;}
}
export class Memo {
  constructor(limit=512,maxKey=10000){this.limit=limit;this.maxKey=maxKey;this.entries=new Map();}
  get(key,compute) {
    if(this.entries.has(key)){const value=this.entries.get(key);this.entries.delete(key);this.entries.set(key,value);return value;}
    const value=compute();if(key.length>this.maxKey)return value;
    this.entries.set(key,value);while(this.entries.size>this.limit)this.entries.delete(this.entries.keys().next().value);
    return value;
  }
}
