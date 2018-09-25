//
// Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//

import ballerina/io;
import ballerina/log;
import pasanw/wordpress;

function closeCSVChannel(io:CSVChannel csvChannel) {
    match csvChannel.close() {
        error channelCloseError => {
            log:printError("Error occured while closing the channel: ",
                err = channelCloseError);
        }
        () => log:printInfo("CSV channel closed successfully.");
    }
}

//keywords is a space seperated list
function textHasWord(string text, string keywords) 
    returns boolean {
        string[] keywordArray = keywords.split(CSV_FILE_KEYWORDS_SEPERATOR);
        foreach keyword in keywordArray {
            if (text.contains(keyword)) {
                return true;
            }
        }
        return false;
}

function commentHasAuthorsKeywords(wordpress:WordpressApiComment comment, 
    wordpress:WordpressApiAuthor author) returns boolean {
        string keywords = authorEmailToKeywordsMap[author.email] ?: "";
        if (keywords == "") {
            return false;
        }
        return textHasWord(comment.content, keywords);
           
}

function populateAuthorPreferencesFromFile() {
    string srcFileName = AUTHOR_PREFERENCES_FILE_NAME;
    io:CSVChannel csvChannel = io:openCsvFile(srcFileName);
    try {
        log:printInfo("Start processing the CSV file");
        match csvChannel.getTable(KeywordPreference) {
            table<KeywordPreference> authorPreferencesTable => {
                foreach rec in authorPreferencesTable {
                    authorEmailToKeywordsMap[rec["authorEmail"]] = rec["keywords"];
                }
            }
            error err => {
                io:println(err.message);
            }
        }
        log:printInfo("Processing completed.");
    } catch (error err) {
        log:printError("An error occurred while processing the records: ",err = err);
    } finally {
        closeCSVChannel(csvChannel);
    }
}

function sendEmail(gmail:MessageRequest email) {
    email.sender = gmailAccount;
    email.subject = EMAIL_SUBJECT;
    var sendMessageResponse = gmailEP -> sendMessage(gmailAccount, email);

    match sendMessageResponse {
        (string, string) sendStatus => {
            string messageId;
            string threadId;
            (messageId, threadId) = sendStatus;
            log:printDebug("Sent Message ID: " + messageId);
            log:printDebug("Sent Thread ID: " + threadId);
        }
        gmail:GmailError err => {
            log:printError("Error when sending email: ", err=err);
        }
    }
}

function getAuthorOfPostThisCommentBelongsTo(wordpress:WordpressApiComment comment) 
    returns wordpress:WordpressApiAuthor|wordpress:WordpressApiError {
        var postResponse = wordpressApiClient->getPostForComment(comment);
        match postResponse {
            wordpress:WordpressApiPost post => {
                var authorResponse = wordpressApiClient->getAuthorForPost(post);
                match authorResponse {
                    wordpress:WordpressApiAuthor author => {
                        return author;
                    }
                    wordpress:WordpressApiError err => {
                        log:printError("Retriving author for post failed: " + 
                            getErrorDescription(err), err = err);
                        return err;
                    }
                }
            }
            wordpress:WordpressApiError err => {
                log:printError("Retriving post for comment failed: " + 
                    getErrorDescription(err), err = err);
                return err;
            }
        }
    }

function getErrorDescription (wordpress:WordpressApiError err) returns string {
    return "Status Code: " + err.statusCode + "|Error description:" + err.message;
} 