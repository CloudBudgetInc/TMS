@RestResource(urlMapping='/inputTest/*')
global with sharing class inputTest {
    
    @httpPost
    //global static Result testInputs(String kjw1, String kjw2, String kjw3){
    global static Result testInputs() {
        String kjw1 = RestContext.request.params.get('kjw1');
        String kjw2 = RestContext.request.params.get('kjw2');
        String kjw3 = RestContext.request.params.get('kjw3');
        return new Result(kjw1, kjw2, kjw3);

    }

    global class Result {
        public String message1;
        public String message2;
        public String message3;

        public Result (String m1, String m2, String m3) {
            message1 = m1;
            message2 = m2;
            message3 = m3;
        }
    }
}