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

import wso2/gmail;
import ballerina/config;
import ballerina/io;
import ballerina/log;

@final string gmailAccessToken = config:getAsString("GMAIL_ACCESS_TOKEN");
@final string gmailClientId = config:getAsString("GMAIL_CLIENT_ID");
@final string gmailClientSecret = config:getAsString("GMAIL_CLIENT_SECRET");
@final string gmailRefreshToken = config:getAsString("GMAIL_REFRESH_TOKEN");
@final string gmailAccount = config:getAsString("GMAIL_ACCOUNT");

endpoint gmail:Client gmailEndPoint {
    clientConfig: {
        auth:{
            accessToken:gmailAccessToken,
            clientId:gmailClientId,
            clientSecret:gmailClientSecret,
            refreshToken:gmailRefreshToken
        }
    }
};

type EmailHandler object {

    function sendEmail(string message, string recepientEmail) {
        gmail:MessageRequest messageRequest = {
            messageBody: EMAIL_BODY + message,
            contentType: gmail:TEXT_PLAIN,
            recipient: recepientEmail,
            sender: gmailAccount,
            subject: EMAIL_SUBJECT
        };   
        
        var sendMessageResponse = gmailEndPoint->sendMessage(gmailAccount, messageRequest);
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
};
