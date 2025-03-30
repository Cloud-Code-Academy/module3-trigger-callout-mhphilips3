/**
 * Wrapper class for parsing the NewsAPI response
 */
public class NewsAPIResponse {
    // TODO: Define fields to match the NewsAPI response structure
    public String status { get; set; }
    public Integer totalResults { get; set; }
    public List<Article> articles { get; set; }
    
    /**
     * Inner class representing a news artile
     */
    public class Article {
        // TODO: Define article fields
        public Source source {get; set;}
        public String author {get; set;}
        public String title {get; set;}
        public String description {get; set;}
        public String url {get; set;}
        public String urlToImage {get; set;}
        public String publishedAt {get; set;}
        public String content {get; set;}

        
        /**
         * Converts the API article to a Salesforce Article__c record
         * @return Article__c The Salesforce record
         */
        public Article__c toSObject() {
            // Implement conversion from API article to Salesforce record
            // Create Article__c record
            Article__c record = new Article__c();
            // Fill in record fields, handle field length limits and null safety
            record.Author__c = author != null ? author.substring(0, Math.min(255, author.length())) : null;
            record.Title__c = title != null ? title.substring(0, Math.min(255, title.length())) : null;
            record.Description__c = description != null ? description.substring(0, Math.min(32768, description.length())) : null;
            record.url__c = url != null ? url.substring(0, Math.min(255, url.length())) : null;
            record.urlToImage__c = urlToImage != null ? urlToImage.substring(0, Math.min(255, urlToImage.length())) : null;
            record.Content__c = content != null ? content.substring(0, Math.min(131072, content.length())) : null;            
            record.Source__c = source.name != null ? source.name.substring(0, Math.min(255, source.name.length())) : null;
            // - Handle date conversion
            record.Published_At__c = Datetime.valueOfGmt(publishedAt.replace('T', ' ').replace('Z', ''));
            // - Generate a unique record name, add generic 'Article' if title is null
            String trimmedTitle = record.Title__c != null ? record.Title__c.substring(0, Math.min(50, record.Title__c.length())) : 'Article';
            record.Name = trimmedTitle + '-' + record.Published_At__c;
            
            
            return record;
        }
    }
    
    /**
     * Inner class representing a news source
     */
    public class Source {
        // TODO: Define source fields
        public String id {get; set;}
        public String name {get; set;}

    }
    
    /**
     * Helper method to convert all articles in this response to Salesforce records
     * @return List<Article__c> List of Salesforce records
     */
    public List<Article__c> toSObjects() {
        // TODO: Implement conversion of all articles to Salesforce records
        return null;
    }
} 