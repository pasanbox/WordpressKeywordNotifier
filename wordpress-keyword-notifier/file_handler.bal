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

import ballerina/io;

type KeywordPreference record{
    string authorEmail,
    string keywords,
};

type StoredData record {
    string configName,
    string configValue,
};

type FileHandler object {
    function closeCSVChannel(io:CSVChannel csvChannel) {
        match csvChannel.close() {
            error channelCloseError => {
                log:printError("Error occured while closing the channel: ",
                    err = channelCloseError);
            }
            () => log:printInfo("CSV channel closed successfully.");
        }
    }

    function populateAuthorKeywordsMap() {
        io:CSVChannel csvChannel = io:openCsvFile(AUTHOR_PREFERENCES_FILE_NAME);
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

    function getLastProcessedComment() returns int {
        int result = 0;
        io:CSVChannel csvChannel = io:openCsvFile(STORED_DATA_FILE_NAME);
        try {
            log:printInfo("Start processing the CSV file for last processed comment");
            match csvChannel.getTable(StoredData) {
                table<StoredData> storedDataTable => {
                    foreach rec in storedDataTable {
                        if(rec["configName"] == "LAST_COMMENT") {
                            var intResult = <int>rec["configValue"];
                            match intResult {
                                int x => {
                                    result = x;
                                }
                                error e=> {
                                    log:printError("Invalid value in file",
                                        err = e);
                                }
                            }
                        }
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
        return result;
    }

    function writeDataToCSVChannel(io:CSVChannel csvChannel, string[]... data) {
        foreach rec in data {
            var returnedVal = csvChannel.write(rec);
            match returnedVal {
                error e => io:println(e.message);
                () => io:println("Record was successfully written to target file");
            }
        }
    }

    function updateLastProcessedComment(int commentId) {
        io:CSVChannel csvChannel = io:openCsvFile(STORED_DATA_FILE_NAME, mode = "w");
        string[][] data = [["LAST_COMMENT", <string>commentId]];
        writeDataToCSVChannel(csvChannel, ...data);
        closeCSVChannel(csvChannel);
    }

};