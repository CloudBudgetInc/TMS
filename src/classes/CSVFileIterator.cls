global with sharing class CSVFileIterator implements Iterator<String>, Iterable<String> {

    private String m_CSVData;
    private String m_introValue;
    
    public CSVFileIterator(Blob fileData, String introValue) {
        m_CSVData = fileData.toString();
        m_introValue = introValue;
    }
    
    global Boolean hasNext() {
        return m_CSVData.length() > 1 ? true : false;
    }
    
	global String Next() {
        
        Integer i=0;
        Integer mv=m_CSVData.indexOf(m_introValue,i);
        Integer mq=m_CSVData.indexOf('"',i);
        
        While (mv>mq&&mq!=-1) {
            Integer j=mq+1;
            mq=m_CSVData.indexOf('"',j);
            if (mq!=-1) {
                j=mq+1;
            }
            mv=m_CSVData.indexOf(m_introValue,j);
            mq=m_CSVData.indexOf('"',j);
        }
        i=mv;
        
 		String row = m_CSVData.subString(0, i);
      	m_CSVData = m_CSVData.subString(i + m_introValue.length(),m_CSVData.length());
        
      	return row;       
    }
    
    global Iterator<String> Iterator() {
    	return this;
    }
}