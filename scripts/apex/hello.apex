// List<News_Category__c> catList = [select Id, Sync__c FROM News_Category__c];
// for (News_Category__c cat : catList){
//     cat.Sync__c = false;
// }
// update catList;
// for (News_Category__c cat : catList){
//     cat.Sync__c = true;
// }
// update catList;


List<Integration_Log__c> logs = [
    SELECT Name, Run_Timestamp__c, Status__c, Records_Processed__c, Run_Group_Id__c, Message__c
    FROM Integration_Log__c
    WHERE Run_Group_Id__c != null
    ORDER BY CreatedDate DESC
    LIMIT 5
];

for (Integration_Log__c log : logs) {
    System.debug('---');
    System.debug('Status: ' + log.Status__c);
    System.debug('Records Processed: ' + log.Records_Processed__c);
    System.debug('Run Group ID: ' + log.Run_Group_Id__c);
    System.debug('Message:\n' + log.Message__c);
}


