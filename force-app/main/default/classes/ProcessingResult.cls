public with sharing class ProcessingResult {
    
    public List<Article__c> articlesToInsert = new List<Article__c>();
    public List<String> messageList = new List<String>{'NewsAPI Sync Log:'};
    public Boolean successRecorded = false;
    public Boolean errorRecorded = false;

    public Integration_Log__c logEntry = new Integration_Log__c(
        Integration_Name__c = 'NewsAPI',
        Run_Timestamp__c = Datetime.now(),
        Records_Processed__c = 0
    );
}