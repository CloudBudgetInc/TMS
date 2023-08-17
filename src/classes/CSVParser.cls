global with sharing class CSVParser implements Iterator<String> {

    private String m_CSVData;
    private Integer m_startPoint;
    
    public CSVParser(String strB) {
        m_CSVData = strB.replaceAll('""', '☺');
        while (m_CSVData.EndsWith(',,')){
            m_CSVData=m_CSVData.removeEnd(',,');
        }
        m_startPoint=0;
    }
    
    global Boolean hasNext() {
        return m_CSVData.length() > 0 ? true : false;
    }
    
	global String Next() {
        
        String strW='';
        Boolean lock=false;
        Integer cLen=1;
        Integer SrcLength = m_CSVData.length();
        
        for (Integer chr=0; chr<SrcLength; chr++) {
            
            String Ch=m_CSVData.mid(chr, 1);
             
            if (Ch=='"') {
                lock=!lock;
                cLen++;
               	continue;
            }
            if (Ch==',' && !lock) {
				break;
            }
            strW += Ch;
        }
        cLen+=strW.length();
      	m_CSVData = m_CSVData.right(SrcLength-cLen);
        strW = strW.replaceAll('☺', '"');
      	return strW;
    }
    
    global Iterator<String> Iterator() {
    	return this;
    }
}