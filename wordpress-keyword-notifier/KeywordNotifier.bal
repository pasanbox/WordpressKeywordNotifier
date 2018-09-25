// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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


import ballerina/config;
import ballerina/io;
import ballerina/log;
import pasanw/wordpress;
import wso2/gmail;

@final string wordpressSiteUrl = config:getAsString("WORDPRESS_SITE_URL");
@final string wordpressUserName = config:getAsString("WORDPRESS_USERNAME");
@final string wordpressPassword = config:getAsString("WORDPRESS_PASSWORD");
@final string gmailAccessToken = config:getAsString("GMAIL_ACCESS_TOKEN");
@final string gmailClientId = config:getAsString("GMAIL_CLIENT_ID");
@final string gmailClientSecret = config:getAsString("GMAIL_CLIENT_SECRET");
@final string gmailRefreshToken = config:getAsString("GMAIL_REFRESH_TOKEN");
@final string gmailAccount = config:getAsString("GMAIL_ACCOUNT");

endpoint wordpress:WordpressApiClient wordpressApiClient {
    url: wordpressSiteUrl,
    userName: wordpressUserName,
    password: wordpressPassword
};

endpoint gmail:Client gmailEP {
    clientConfig: {
        auth:{
            accessToken:gmailAccessToken,
            clientId:gmailClientId,
            clientSecret:gmailClientSecret,
            refreshToken:gmailRefreshToken
        }
    }
};

public type KeywordPreference record {
    string authorEmail,
    string keywords,
};

map<string> authorEmailToKeywordsMap;

function main(string... args) {
    populateAuthorPreferencesFromFile();

    var wordpressApiResponse = wordpressApiClient->getAllComments();
    match wordpressApiResponse {
        wordpress:WordpressApiComment[] wordpressComments => {
            foreach wordpressComment in wordpressComments {
                notifyAuthorIfCommentHasKeyword(wordpressComment);       
            }
        }
        wordpress:WordpressApiError err => {
            log:printError("Retriving comments failed: " + getErrorDescription(err), err = err);
        }
    }
}

function notifyAuthorIfCommentHasKeyword(wordpress:WordpressApiComment wordpressComment) {
    var authorResponse = getAuthorOfPostThisCommentBelongsTo(wordpressComment);
    match authorResponse {
        wordpress:WordpressApiAuthor wordpressAuthor => {
            if (commentHasAuthorsKeywords(wordpressComment, wordpressAuthor)) {
                gmail:MessageRequest messageRequest = {
                    messageBody: "Following comment matches your keywords: " + wordpressComment.content,
                    contentType: gmail:TEXT_PLAIN,
                    recipient: wordpressAuthor.email
                };   
                sendEmail(messageRequest);
            }     
        }
        wordpress:WordpressApiError err => {
            log:printError("Retriving original author for comment failed: " + 
                getErrorDescription(err), err = err);
        }
    }    
}

