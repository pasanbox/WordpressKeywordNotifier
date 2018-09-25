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

documentation { Checks if a text has matches in a keywords list
        P{{text}} - Text used for the search
        P{{keywords}} - Space seperated list of keywords
}

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
        string keywords = authorEmailToKeywordsMap[author.email] ?: EMPTY_STRING;
        if (keywords == EMPTY_STRING) {
            return false;
        }
        return textHasWord(comment.content, keywords);     
}

function getErrorDescription (wordpress:WordpressApiError err) returns string {
    return "Status Code: " + err.statusCode + "|Error description:" + err.message;
} 