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

EmailHandler emailHandler = new;
FileHandler fileHandler = new;

@final string wordpressSiteUrl = config:getAsString("WORDPRESS_SITE_URL");
@final string wordpressUserName = config:getAsString("WORDPRESS_USERNAME");
@final string wordpressPassword = config:getAsString("WORDPRESS_PASSWORD");

int lastCommentFromPreviousRun = fileHandler.getLastProcessedComment();
int lastCommentFromThisRun = lastCommentFromPreviousRun;
map<string> authorEmailToKeywordsMap;

endpoint wordpress:WordpressApiClient wordpressApiClient {
    url: wordpressSiteUrl,
    userName: wordpressUserName,
    password: wordpressPassword
};

function main(string... args) {
    fileHandler.populateAuthorKeywordsMap();

    var wordpressApiResponse = wordpressApiClient->getAllComments();
    match wordpressApiResponse {
        wordpress:WordpressApiComment[] wordpressComments => {
            foreach wordpressComment in wordpressComments {
                notifyAuthorIfCommentHasKeyword(wordpressComment);
            }
            fileHandler.updateLastProcessedComment(lastCommentFromThisRun);
        }
        wordpress:WordpressApiError err => {
            log:printError("Retrieving comments failed: " + getErrorDescription(err), err = err);
        }
    }
}

function notifyAuthorIfCommentHasKeyword(wordpress:WordpressApiComment wordpressComment) {
    if(wordpressComment.id <= lastCommentFromPreviousRun) {
        log:printInfo("Comment " + wordpressComment.id + ": already processed");
        return;
    }

    var authorResponse = getAuthorOfPostThisCommentBelongsTo(wordpressComment);
    match authorResponse {
        wordpress:WordpressApiAuthor wordpressAuthor => {
            if (commentHasAuthorsKeywords(wordpressComment, wordpressAuthor)) {
                emailHandler.sendEmail(wordpressComment.content, wordpressAuthor.email);
                setLastProcessedComment(wordpressComment);
            }
        }
        wordpress:WordpressApiError err => {
            log:printError("Retriving original author for comment failed: " +
                getErrorDescription(err), err = err);
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

//If comment from last run from 50 and
//API returns comments like 55,54,53.....45
//we process only [55..51]
//and write 55 in file
function setLastProcessedComment(wordpress:WordpressApiComment comment) {
    if(comment.id > lastCommentFromThisRun) {
        lastCommentFromThisRun = comment.id;
    }
}
