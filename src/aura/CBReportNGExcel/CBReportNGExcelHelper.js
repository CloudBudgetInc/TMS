/**
 * Created by Alex JR on 22/02/19.
 */
({
    /**
     * cb4__CBReport__c object by Id
     */
    helpGetReport: function (cmp) {
        _CBRequest(cmp, "c.getReportServer", {"reportId": cmp.get("v.recordId")}, "v.report", null, null, _TEXT.REPORT.FAILED_GET_REPORT, false);
    },

    /**
     * cb4__CBReport__c object by Id
     */
    helpGetReportColumnsServer: function (cmp) {
        _CBRequest(cmp, "c.getReportColumnsServer", {"reportId": cmp.get("v.recordId")}, "v.reportColumns", null, null, _TEXT.REPORT.FAILED_GET_REPORT, false);
    },

    helpGetTableHeaders: function (cmp) {
        let _this = this;

        function callback() {
            let headers = cmp.get("v.tableHeaders");
            let numberOfTextColumns = headers.pop();
            cmp.set("v.tableHeaders", headers);
            cmp.set("v.tableHeadersOriginal", headers);
            cmp.set("v.numberOfTextColumns", numberOfTextColumns);
        }

        _CBRequest(cmp, "c.getReportHeadersServer", {"reportId": cmp.get("v.recordId")}, "v.tableHeaders", callback, null, _TEXT.REPORT.FAILED_GET_REPORT, false);
    },

    helpGetCBalances: function (cmp) {
        try {
            let _this = this;

            function callback() {
                try {
                    const CBals = cmp.get("v.CBals");

                    if (CBals === null || CBals.length === 0) {
                        _CBMessages.fireOtherMessage(_TEXT.REPORT.HAVE_NO_DATA);
                        cmp.set("v.tableHeaders", []);
                        _hideSpinner(cmp);
                        return;
                    }
                    cmp.set("v.fitPageEnabled", cmp.get("v.report.cb4__FitToPageEnabled__c"));
                    _this.helpGenerateReportLines(cmp);
                    _this.helpGetFilterSelectOptions(cmp);

                    _this.helpRefreshReportData(cmp);
                } catch (e) {
                    alert("helpGetCBalances " + e);
                }

            }

            _CBRequest(cmp, "c.getCBalancesServer", {"reportId": cmp.get("v.recordId")}, "v.CBals", callback, null, _TEXT.REPORT.FAILED_GET_REPORT, false);
        } catch (e) {
            alert(e);
        }
    },

    /**
     * The main rerender controller
     */
    helpRefreshReportData: function (cmp, justExcel) {
        try {
            _cl('DATA UPDATING', 'yellow');

            // refresh data from the source
            let origin = JSON.parse(JSON.stringify(cmp.get("v.rowsOriginal")));
            //cmp.set("v.rows", origin);

            let columns = JSON.parse(JSON.stringify(cmp.get("v.reportColumnsOriginal")));
            cmp.set("v.reportColumns", columns);

            let header = JSON.parse(JSON.stringify(cmp.get("v.tableHeadersOriginal"))); //cmp.set("v.tableHeadersOrigin", headers);
            cmp.set("v.tableHeaders", header);

            let _this = this;

            function manageRows() {
                cmp.set("v.rows", origin);
                _this.helpApplyDimensionFilter(cmp); // dimension filter
                if (cmp.get("v.rows").length === 0) {
                    _CBMessages.fireOtherMessage(_TEXT.REPORT.HAVE_NO_DATA);
                    return;
                }
                _this.helpCalculateColumnTotals(cmp); // vertical totals
                _this.helpCalculateRowTotals(cmp); // horizontal total
            }

            /////////////   THE MAX NUMBER OF ROWS    ///////////
            let maxNumber = cmp.get("v.report.cb4__MaxRowNumber__c");
            if (_isInvalid(maxNumber)) maxNumber = 200;
            _cl('MAX LINES NUMBER IS ' + maxNumber + '. CURRENT LIST SIZE IS ' + cmp.get("v.rows").length, 'green');

            if (cmp.get("v.rows").length === 0 && cmp.get("v.rowsOriginal").length > maxNumber) { // FIRST RUN AND OVERLOAD
                _cl('FULL RUN SKIPPING.....', 'red');
                cmp.set("v.rows", origin);
            } else {
                _cl('FULL RUN.....', 'red');
                manageRows();
            }


            let d1f = cmp.get("v.d1filter");
            let d2f = cmp.get("v.d2filter");
            if (cmp.get("v.rows").length > maxNumber && cmp.get("v.dimensions.D1") != null && _isInvalid(d1f)) { // if the list of rows has more than X records try to filter by the first option
                let d1SO = cmp.get('v.d1SO');
                cmp.set("v.d1filter", d1SO[0]);
                _CBMessages.fireOtherMessage(_TEXT.REPORT.MAX_ROW_SIZE_MESSAGE);
                _cl('FIRST DIMENSION LIMITED RUN.....', 'red');
                manageRows(); // start again
            }

            if (cmp.get("v.rows") > maxNumber && cmp.get("v.dimensions.D2") != null && _isInvalid(d2f)) {
                // if the first option is already selection try to select the second one
                let d2SO = cmp.get('v.d2SO');
                cmp.set("v.d2filter", d2SO[0]);
                _CBMessages.fireOtherMessage(_TEXT.REPORT.MAX_ROW_SIZE_MESSAGE);
                _cl('SECOND DIMENSION LIMITED RUN.....', 'red');
                manageRows(); // and again
            }
            /////////////   THE MAX NUMBER OF ROWS    ///////////

            this.helpFormatNumbers(cmp); // formatting

            this.helpShowHideSimpleRows(cmp); // total rows only filter
            this.helpApplyColumnsFilter(cmp); // display only allowed columns filter

            if (justExcel) {
                this.helpDownloadExcel(cmp);
                return;
            }

            this.helpRenderTable(cmp); // html generation
            this.applyJQueryDataTable(cmp); // apply jQuery datatable if needed

            cmp.set("v.showExportButtons", true);
            this.showHeaderAndTable(cmp);

        } catch (e) {
            alert("helpRefreshReportData ERROR " + e);
        }
    },

    helpDeleteSubtotalLines: function (cmp, rows) {
        rows = rows.map(function (item) {
            if (!item.isTotal) return item;
        });
    },

    /**
     * The same helpRefreshReportData but with spinner
     */
    helpRefreshReportDataAfterSpinner: function (cmp) {
        _showSpinner(cmp);
        this.hideHeaderAndTable(cmp);
        let _this = this;

        window.setTimeout(
            $A.getCallback(function () {
                _this.helpRefreshReportData(cmp);
            }), 10);
    },

    /**
     * Function generates html using jQuery. GenerateTable
     */
    helpRenderTable: function (cmp) {
        _cl("helpRenderTable", "yellow");
        try {
            const tableHeaders = cmp.get("v.tableHeaders");
            const rows = cmp.get("v.rows");
            const columns = cmp.get('v.reportColumns');
            let colorMap = {};
            for (let i = 0; i < columns.length; i++) colorMap[i] = _isInvalid(columns[i].cb4__Color__c) || columns[i].cb4__Color__c === 'white' ? '' : columns[i].cb4__Color__c;

            let tableDiv = $(cmp.find("auraReportId").getElement());
            tableDiv.empty();
            let table = $("<table></table>").attr('id', 'mt').addClass("display cell-border compact slds-table_col-bordered").css("width", "100%");

            // HEADER
            let thead = $("<thead></thead>");
            let theadtr = $("<tr></tr>").addClass("slds-text-title_caps");
            let idxth = $("<th>#</th>").css("padding", "1px");
            theadtr.append(idxth);

            tableHeaders.forEach(function (header) {
                let headElem = $("<th></th>");
                headElem.append($("<div> " + header + " </div>").addClass("slds-truncate topRow header"));
                theadtr.append(headElem);
            });

            thead.append(theadtr);
            table.append(thead);
            // HEADER

            // BODY
            let tbody = $("<tbody></tbody>");
            let j, oneTableRow;

            rows.forEach(function (row, idx) {
                oneTableRow = $("<tr></tr>").addClass(row.type);
                oneTableRow.append($("<td></td>").addClass("index centerText").append(idx + 1));

                if (row.l1 !== undefined) oneTableRow.append($("<td></td>").addClass("slds-truncate tableText").append(row.l1));
                if (row.l2 !== undefined) oneTableRow.append($("<td></td>").addClass("slds-truncate tableText").append(row.l2));
                if (row.l3 !== undefined) oneTableRow.append($("<td></td>").addClass("slds-truncate tableText").append(row.l3));
                if (row.l4 !== undefined) oneTableRow.append($("<td></td>").addClass("slds-truncate tableText").append(row.l4));
                if (row.l5 !== undefined) oneTableRow.append($("<td></td>").addClass("slds-truncate tableText").append(row.l5));
                if (row.l6 !== undefined) oneTableRow.append($("<td></td>").addClass("slds-truncate tableText").append(row.l6));
                if (row.l7 !== undefined) oneTableRow.append($("<td></td>").addClass("slds-truncate tableText").append(row.l7));

                for (j = 0; j < row.v.length; j++) {
                    oneTableRow.append($("<td></td>").attr("id", row.k + '*' + j).addClass(row.isTotal ? '' : colorMap[j]).append(row.v[j]));
                }

                tbody.append(oneTableRow);
            });

            table.append(tbody);

            tableDiv.append(table);

            let _this = this;
            setTimeout(function () {
                _cl("Drill Down On", "blue");
                $("td[id*='*']").click(function () {
                    try {
                        const id = $(this).attr("id");
                        console.log("ID=" + id);
                        _this.helpGetDrillDown(cmp, id);
                    } catch (e) {
                        alert(e);
                    }
                });
            }, 2000);


        } catch (e) {
            alert("helpRenderTable ERROR " + e);
        }

    },

    helpGenerateReportLines: function (cmp) {
        //_cl("helpGenerateReportLines", 'yellow');

        "helpGenerateReportLines".toConsole();

        function updateRLLevels(rl, ns, num, bal) {
            const truncate = 50;
            for (let i = 1; i <= num; i++) {
                if (num >= 1) {
                    if (bal['cb4__Lvl' + i + 'Name__c'] === undefined) {
                        rl['l' + i] = rl['l' + i + 'Long'] = ns;
                    } else {
                        rl['l' + i] = bal['cb4__Lvl' + i + 'Name__c'].truncate(truncate);
                        rl['l' + i + 'Long'] = bal['cb4__Lvl' + i + 'Name__c'];
                    }
                }
            }
        }

        function getKeyObject(balPeriod) {
            return {
                key1: balPeriod + 'cb4__Amount1__c',
                key2: balPeriod + 'cb4__Amount2__c',
                key3: balPeriod + 'cb4__Amount3__c',
                key4: balPeriod + 'cb4__Amount4__c',
                key5: balPeriod + 'cb4__Amount5__c',
                key1YTD: balPeriod + 'cb4__Amount1YTD__c',
                key2YTD: balPeriod + 'cb4__Amount2YTD__c',
                key3YTD: balPeriod + 'cb4__Amount3YTD__c',
                key4YTD: balPeriod + 'cb4__Amount4YTD__c',
                key5YTD: balPeriod + 'cb4__Amount5YTD__c',
                key2_1: balPeriod + 'cb4__Amount2_1__c',
                key2_1YTD: balPeriod + 'cb4__Amount2_1YTD__c'
                //percent1: balPeriod + 'cb4__Percent1__c',
            }
        }

        try {
            let columns = cmp.get("v.reportColumns");
            cmp.set("v.reportColumnsOriginal", JSON.parse(JSON.stringify(columns)));
            let balances = cmp.get("v.CBals");
            let num = cmp.get("v.numberOfTextColumns");
            let report = cmp.get("v.report");
            const ns = _isInvalid(report.cb4__notSpecifiedTitle__c) ? 'N/A' : report.cb4__notSpecifiedTitle__c;

            // _cl("columns size=" + columns.length, 'green');
            // _cl("balances size=" + balances.length, 'green');
            // _cl("balance line=" + JSON.stringify(balances[0]), 'green');
            // _cl("number of text columns=" + num, 'green');
            // _cl("Report = " + report, 'green');

            // report line is a zeroed template of horizontal report line
            let reportLine = {}; // object has fields like "periodId + amountField" for example "a021U000007aOjzQAEcb4__Amount2__c"
            columns.forEach(function (col) {
                let perId = col.cb4__Column__c === undefined ?
                    col.cb4__ReportColumn1__c + col.cb4__ReportColumn2__c + col.cb4__ReportColumn3__c + col.cb4__ReportColumn4__c
                    : col.cb4__Column__c;
                let amountField = col.cb4__CBalanceAmountField__c === undefined ? '' : col.cb4__CBalanceAmountField__c;
                reportLine[perId + amountField] = 0;
            });
            //_cl('Report Line Simple EXAMPLE = ' + JSON.stringify(reportLine), 'orange');

            let reportLineObj = {}; // key =  unique CBalance key (temp storage like a map)

            let balKey, balPeriod, rl,
                balAmount1, balAmount2, balAmount3, balAmount4, balAmount5, balAmount2_1,
                balAmount1YTD, balAmount2YTD, balAmount3YTD, balAmount4YTD, balAmount5YTD, balAmount2_1YTD;
            balances.forEach(function (bal) {
                balKey = bal.cb4__Key__c;
                balPeriod = bal.cb4__Column__c;
                balAmount1 = bal.cb4__Amount1__c;
                balAmount2 = bal.cb4__Amount2__c;
                balAmount3 = bal.cb4__Amount3__c;
                balAmount4 = bal.cb4__Amount4__c;
                balAmount5 = bal.cb4__Amount5__c;
                balAmount1YTD = bal.cb4__Amount1YTD__c;
                balAmount2YTD = bal.cb4__Amount2YTD__c;
                balAmount3YTD = bal.cb4__Amount3YTD__c;
                balAmount4YTD = bal.cb4__Amount4YTD__c;
                balAmount5YTD = bal.cb4__Amount5YTD__c;
                balAmount2_1 = bal.cb4__Amount2_1__c;
                balAmount2_1YTD = bal.cb4__Amount2_1YTD__c;
                //balPercent1 = bal.cb4__Percent1__c;
                //rl - is one report line. {period1 + 'cb4__Amount1__c' :  54, period1 + 'cb4__Amount2__c' : 5 }
                rl = reportLineObj[balKey]; // CBalance try to finds its reportLine
                if (rl === undefined) { // the first meeting -> clone object
                    rl = JSON.parse(JSON.stringify(reportLine));
                    rl.key = balKey;
                    reportLineObj[balKey] = rl; //cb4__notSpecifiedTitle__c
                    updateRLLevels(rl, ns, num, bal)
                }

                let k = getKeyObject(balPeriod); // key storage   key1 =  balPeriod + 'cb4__Amount1__c'. Mapping for shorting the field name

                if (balAmount1 !== 0 && rl[k.key1] !== undefined) rl[k.key1] = _isInvalid(rl[k.key1]) ? balAmount1 : rl[k.key1] - 0 + balAmount1 - 0;
                if (balAmount2 !== 0 && rl[k.key2] !== undefined) rl[k.key2] = _isInvalid(rl[k.key2]) ? balAmount2 : rl[k.key2] - 0 + balAmount2 - 0;
                if (balAmount3 !== 0 && rl[k.key3] !== undefined) rl[k.key3] = _isInvalid(rl[k.key3]) ? balAmount3 : rl[k.key3] - 0 + balAmount3 - 0;
                if (balAmount4 !== 0 && rl[k.key4] !== undefined) rl[k.key4] = _isInvalid(rl[k.key4]) ? balAmount4 : rl[k.key4] - 0 + balAmount4 - 0;
                if (balAmount5 !== 0 && rl[k.key5] !== undefined) rl[k.key5] = _isInvalid(rl[k.key5]) ? balAmount5 : rl[k.key5] - 0 + balAmount5 - 0;

                if (balAmount1YTD !== 0 && rl[k.key1YTD] !== undefined) rl[k.key1YTD] = _isInvalid(rl[k.key1YTD]) ? balAmount1YTD : rl[k.key1YTD] - 0 + balAmount1YTD - 0;
                if (balAmount2YTD !== 0 && rl[k.key2YTD] !== undefined) rl[k.key2YTD] = _isInvalid(rl[k.key2YTD]) ? balAmount2YTD : rl[k.key2YTD] - 0 + balAmount2YTD - 0;
                if(rl[k.key2YTD] !== undefined && rl[k.key1YTD] !== undefined) {
                    rl[k.key3YTD] = rl[k.key2YTD] - rl[k.key1YTD];
                    if (Math.abs(rl[k.key3YTD]) <= 0.5) rl[k.key3YTD] = 0;
                    if (rl[k.key2_1YTD] !== undefined) {
                        if ((Math.abs(rl[k.key2YTD]) >= Math.abs(rl[k.key1YTD]))) {
                            rl[k.key2_1YTD] = 0;
                        } else {
                            rl[k.key2_1YTD] = rl[k.key1YTD] - rl[k.key2YTD];
                        }
                        if (Math.abs(rl[k.key2_1YTD]) < 0.5) rl[k.key2_1YTD] = 0;
                    }
                }
                //if (balAmount4YTD !== 0 && rl[k.key4YTD] !== undefined) rl[k.key4YTD] = _isInvalid(rl[k.key4YTD]) ? balAmount4YTD : rl[k.key4YTD] - 0 + balAmount4YTD - 0;
                if(rl[k.key2YTD] !== undefined && rl[k.key1YTD] !== undefined) rl[k.key4YTD] = rl[k.key1YTD] !== 0 ? (rl[k.key2YTD] / rl[k.key1YTD] * 100) : 0;
                if (balAmount5YTD !== 0 && rl[k.key5YTD] !== undefined) rl[k.key5YTD] = _isInvalid(rl[k.key5YTD]) ? balAmount5YTD : rl[k.key5YTD] - 0 + balAmount5YTD - 0;

                if (balAmount2_1 !== 0 && rl[k.key2_1] !== undefined) rl[k.key2_1] = (_isInvalid(rl[k.key2]) ? 0 : rl[k.key2]) - 0 - (_isInvalid(rl[k.key1]) ? 0 : rl[k.key1]) - 0;
                //if (balAmount2_1YTD !== 0 && rl[k.key2_1YTD] !== undefined) rl[k.key2_1YTD] = (_isInvalid(rl[k.key2YTD]) ? 0 : rl[k.key2YTD]) - 0 - (_isInvalid(rl[k.key1YTD]) ? 0 : rl[k.key1YTD]) - 0;

                //if (balPercent1 !== 0 && rl[k.percent1] !== undefined) rl[k.percent1] = _isInvalid(rl[k.percent1]) ? balPercent1 : rl[k.percent1] - 0 + balPercent1 - 0;
            });

            /*    //_cl('BEFORE = ' + JSON.stringify(reportLineObj), 'red');*/
            //_cl("reportLineObj size=" + Object.keys(reportLineObj).length, 'green');

            let rows = [];

            for (let rlKey in reportLineObj) {
                rl = reportLineObj[rlKey];
                let line = {
                    v: [],
                    k: rl.key,
                };
                for (let i = 1; i <= 7; i++) {
                    line["l" + i] = rl["l" + i];
                    line["l" + i + "Long"] = rl["l" + i + "Long"];
                }
                for (let rlField in rl) if (rlField.length > 18) line.v.push(rl[rlField]);
                rows.push(line);
            }
            cmp.set("v.rowsOriginal", JSON.parse(JSON.stringify(rows)));
        } catch (e) {
            alert('GenerateReportLines - ' + e);
        }
    },

    helpCalculateColumnTotals: function (cmp) {
        _cl("helpCalculateColumnTotals", "yellow");
        try {
            let columns = cmp.get("v.reportColumns");
            let rows = cmp.get("v.rows");
            let _this = this;

            let colNumMap = {};
            for (let i = 0; i < columns.length; i++) colNumMap[columns[i].Id] = i;

            let numberOfSourceCols, numberOfResultColumn;
            columns.forEach(function (col) {

                if (col.cb4__Column__c === undefined) { // it means that this column is total type
                    numberOfSourceCols = [];
                    if (col.cb4__ReportColumn1__c !== undefined) numberOfSourceCols.push({
                        v: colNumMap[col.cb4__ReportColumn1__c],
                        s: _isInvalid(col.cb4__Relation1__c) ? '+' : col.cb4__Relation1__c
                    });
                    if (col.cb4__ReportColumn2__c !== undefined) numberOfSourceCols.push({
                        v: colNumMap[col.cb4__ReportColumn2__c],
                        s: _isInvalid(col.cb4__Relation2__c) ? '+' : col.cb4__Relation2__c
                    });
                    if (col.cb4__ReportColumn3__c !== undefined) numberOfSourceCols.push({
                        v: colNumMap[col.cb4__ReportColumn3__c],
                        s: _isInvalid(col.cb4__Relation3__c) ? '+' : col.cb4__Relation3__c
                    });
                    if (col.cb4__ReportColumn4__c !== undefined) numberOfSourceCols.push({
                        v: colNumMap[col.cb4__ReportColumn4__c],
                        s: _isInvalid(col.cb4__Relation4__c) ? '+' : col.cb4__Relation4__c
                    });
                    numberOfResultColumn = colNumMap[col.Id];

                    _this.helpCalculateColumnAmounts(cmp, rows, numberOfSourceCols, numberOfResultColumn);
                }
            });
            cmp.set("v.rows", rows);
        } catch (e) {
            alert("helpCalculateColumnTotals: " + e);
        }

    },

    helpCalculateColumnAmounts: function (cmp, rows, numberOfSourceCols, numberOfResultColumn) {
        try {
            let amounts, total;
            for (let i = rows.length; i--;) {
                amounts = rows[i].v;
                total = 0;
                numberOfSourceCols.forEach(function (item) {
                    total += item.s === '+' ? amounts[item.v] - 0 : amounts[item.v] * -1;
                });
                if(numberOfSourceCols.length === 2){
                    if((Math.abs(amounts[numberOfSourceCols[1].v]) >= Math.abs(amounts[numberOfSourceCols[0].v])) || Math.abs(total) < 0.6){
                        total = 0;
                    }
                }
                amounts[numberOfResultColumn] = total;
            }
        } catch (e) {
            alert("helpCalculateColumnAmounts  = " + e);
        }
    },

    helpCalculateRowTotals: function (cmp) {
        _cl("helpCalculateRowTotal", "yellow");
        try {
            let rows = cmp.get("v.rows");
            const num = cmp.get("v.numberOfTextColumns");
            const t = cmp.get("v.report.cb4__SubtotalsBy__c").split(',');
            let columns = cmp.get("v.reportColumns");
            let globalTotalRow = this.getGlobalTotalRow(rows, columns);
            globalTotalRow.isTotal = true;
            globalTotalRow.type = 'total';
            for (let i = 7; i--;) if (t[i] === "true") rows = this.helpAddSubtotalRows(rows, i + 1, num, columns);
            rows.unshift(globalTotalRow);
            cmp.set("v.rows", rows);

        } catch (e) {
            alert("helpCalculateRowTotals ERROR " + e);
        }

    },

    getGlobalTotalRow: function (rows, columns) {
        try {
            let globalTotalRow = this.getSumRowFromRows(rows, columns);
            globalTotalRow.l1 = globalTotalRow.l1Long = 'TOTAL';
            for (let i = 2; i <= 7; i++) if (rows[0]["l" + i] !== undefined) globalTotalRow["l" + i] = globalTotalRow["l" + i + "Long"] = '';
            return globalTotalRow;
        } catch (e) {
            alert("getGlobalTotalRow = " + e);
        }
    },

    /**
     *
     * @param rows list of rows
     * @param lvlNum grouping stage (level)
     * @param num number of text columns
     * @returns {[]}
     */
    helpAddSubtotalRows: function (rows, lvlNum, num, columns) {
        try {
            let lvlNameField = "l" + lvlNum; // l1, l2 or l3 ..... depends on level
            let newRows = [];
            let oneTypeArray = [];
            let mark, newMark, j, previousRow, localKey, localKeyLong;


            for (let i = 0; i < rows.length; i++) {
                let row = rows[i];
                if (row.isTotal) { // total of subtotal row met
                    newRows.push(row);
                    continue;
                }
                newMark = this.getRowMark(row, lvlNum);
                if (mark === undefined) { // first row met
                    mark = newMark;
                    newRows.push(row);
                    oneTypeArray.push(row); // collection of rows bounded to the common mark
                    previousRow = row;
                    continue;
                }
                if (mark !== newMark) {
                    mark = newMark;
                    let subTotalRow = this.getSumRowFromRows(oneTypeArray, columns);
                    for (j = 1; j <= num; j++) {
                        localKey = "l" + j;
                        localKeyLong = "l" + j + "Long";
                        subTotalRow[localKey] = lvlNum >= j ? previousRow[localKey] : '-';
                        subTotalRow[localKeyLong] = lvlNum >= j ? previousRow[localKeyLong] : '-';
                    }
                    subTotalRow.isTotal = true;
                    subTotalRow.type = 'subTotal' + lvlNum;
                    newRows.push(subTotalRow);
                    oneTypeArray = [];
                }
                previousRow = row;
                newRows.push(row);
                oneTypeArray.push(row);
            }

            let subTotalRow = this.getSumRowFromRows(oneTypeArray, columns);
            for (j = 1; j <= num; j++) {
                let localKey = "l" + j;
                let localKeyLong = "l" + j + "Long";
                subTotalRow[localKey] = lvlNum >= j ? previousRow[localKey] : '-';
                subTotalRow[localKeyLong] = lvlNum >= j ? previousRow[localKeyLong] : '-';
            }
            subTotalRow.isTotal = true;
            subTotalRow.type = 'subTotal' + lvlNum;
            newRows.push(subTotalRow);
            return newRows;
        } catch (e) {
            alert("helpAddSubtotalRows = " + e);
        }
    },

    getRowMark: function (row, lvlNum) {
        switch (lvlNum) {
            case 1:
                return row.l1;
            case 2:
                return row.l1 + row.l2;
            case 3:
                return row.l1 + row.l2 + row.l3;
            case 4:
                return row.l1 + row.l2 + row.l3 + row.l4;
            case 5:
                return row.l1 + row.l2 + row.l3 + row.l4 + row.l5;
            case 6:
                return row.l1 + row.l2 + row.l3 + row.l4 + row.l5 + row.l6;
            case 7:
                return row.l1 + row.l2 + row.l3 + row.l4 + row.l5 + row.l6 + row.l7;
        }
    },

    getSumRowFromRows: function (rows, columns) {
        try {
            let newRow = {};
            newRow.v = [];
            let i, j;
            const arrLength = rows[0].v.length;
            for (i = arrLength; i--;) newRow.v[i] = 0;
            for (i = rows.length; i--;) {
                for (j = 0; j < arrLength; j++) {
                    if (columns[j].cb4__Type__c === 'percent') {
                        newRow.v[j] = 0;
                        continue;
                    }
                    /*if (i === 0 && columns[j].cb4__CBalanceAmountField__c === 'cb4__Amount2_1YTD__c') {
                        if (Math.abs(newRow.v[j - 4]) >= Math.abs(newRow.v[j - 1])) newRow.v[j] = 0;
                        else newRow.v[j] = parseFloat(newRow.v[j - 1]) - parseFloat(newRow.v[j - 4]);
                    } else {*/
                        newRow.v[j] += parseFloat(rows[i].v[j]);
                    //}
                }
            }
            return newRow;
        } catch (e) {
            alert("getSumRowFromRows = " + e);
        }
    },

    helpFormatNumbers: function (cmp) {
        _cl("helpFormatNumbers", "yellow");
        try {
            let columns = cmp.get("v.reportColumns");
            let i, j;

            let report = cmp.get("v.report");
            let fractionDigits = _isInvalidNumber(report.cb4__FractionDigits__c) ? 0 : report.cb4__FractionDigits__c;
            let rows = cmp.get("v.rows");
            const numberFormat = new Intl.NumberFormat('en-US', {
                maximumFractionDigits: fractionDigits,
                minimumFractionDigits: fractionDigits
            });

            for (i = rows.length; i--;) {
                rows[i].v = rows[i].v.map(numberFormat.format);
                rows[i].v = rows[i].v.map(function (amount, idx) {
                    if (columns[idx].cb4__Type__c === 'percent') if ((amount - 0) === 0) amount = '-'; else amount += ' %';
                    return amount;
                });
            }
            cmp.set("v.rows", rows);
        } catch (e) {
            alert("helpFormatNumbers ERROR = " + e);
        }
    },

    /**
     * Group of columns to display
     */
    helpGetDisplayGroups: function (cmp) {
        let _this = this;

        function callback() {
            _cl("helpGetDisplayGroups", "yellow");
            let columnsOptions = cmp.get("v.columnsOptions");
            let options = [];
            for (let i = 0; i < columnsOptions.length; i++) {
                const opt = columnsOptions[i].trim();
                options.push({
                    label: opt,
                    value: opt
                });
            }
            cmp.set("v.columnsOptions", options);
        }

        _CBRequest(cmp, "c.getDisplayGroupsServer", {"reportId": cmp.get("v.recordId")}, "v.columnsOptions", callback, null, _TEXT.REPORT.FAILED_GET_REPORT, false);
    },

    showHeaderAndTable: function (cmp) {
        let tableDiv = cmp.find("tableDiv");
        $A.util.removeClass(tableDiv, "slds-hide");

        let tableHeader = cmp.find("tableHeader");
        $A.util.removeClass(tableHeader, "slds-hide");
    },

    hideHeaderAndTable: function (cmp) {
        let tableDiv = cmp.find("tableDiv");
        $A.util.addClass(tableDiv, "slds-hide");
    },

    /////// HEADER FILTERS ///////
    /**
     * The method populate header dropdown select options
     */
    helpGetFilterSelectOptions: function (cmp) {
        try {
            let d1 = cmp.get('v.d1SO');
            if (d1.length !== 0) return;
            const rows = cmp.get("v.rowsOriginal");
            const numberOfTextColumns = cmp.get("v.numberOfTextColumns");
            const tableHeaders = cmp.get("v.tableHeaders");
            let d1SO = {};
            let d2SO = {};
            let d3SO = {};
            let d4SO = {};
            let d5SO = {};
            let d6SO = {};
            let d7SO = {};
            let mapSO = [d1SO, d2SO, d3SO, d4SO, d5SO, d6SO, d7SO];

            let j, name;
            for (let i = 0; i < rows.length; i++) {
                for (j = 1; j <= numberOfTextColumns; j++) {
                    if (rows[i].type !== undefined) continue;
                    name = rows[i]['l' + j];
                    mapSO[j - 1][name] = true;
                }
            }
            let dimensions = {};
            for (j = 1; j <= numberOfTextColumns; j++) dimensions['D' + j] = tableHeaders[j - 1];

            cmp.set('v.d1SO', Object.keys(mapSO[0]));
            cmp.set('v.d2SO', Object.keys(mapSO[1]));
            cmp.set('v.d3SO', Object.keys(mapSO[2]));
            cmp.set('v.d4SO', Object.keys(mapSO[3]));
            cmp.set('v.d5SO', Object.keys(mapSO[4]));
            cmp.set('v.d6SO', Object.keys(mapSO[5]));
            cmp.set('v.d7SO', Object.keys(mapSO[6]));
            cmp.set('v.dimensions', dimensions);
        } catch (e) {
            alert("helpGetFilterSelectOptions = " + e);
        }
    },
    /**
     * Apply Dimension filters of the page
     */
    helpApplyDimensionFilter: function (cmp) {
        _cl("helpApplyDimensionFilter", 'yellow');
        try {
            let _this = this;

            let rows = cmp.get("v.rows");
            let d1f = cmp.get("v.d1filter");
            let d2f = cmp.get("v.d2filter");
            let d3f = cmp.get("v.d3filter");
            let d4f = cmp.get("v.d4filter");
            let d5f = cmp.get("v.d5filter");
            let d6f = cmp.get("v.d6filter");
            let d7f = cmp.get("v.d7filter");


            rows = rows.filter(function (r) {
                let opted = true;
                if (!_isInvalid(d1f) && r.l1 !== d1f) opted = false;
                if (!_isInvalid(d2f) && r.l2 !== d2f) opted = false;
                if (!_isInvalid(d3f) && r.l3 !== d3f) opted = false;
                if (!_isInvalid(d4f) && r.l4 !== d4f) opted = false;
                if (!_isInvalid(d5f) && r.l5 !== d5f) opted = false;
                if (!_isInvalid(d6f) && r.l6 !== d6f) opted = false;
                if (!_isInvalid(d7f) && r.l7 !== d7f) opted = false;
                return opted;
            });

            cmp.set("v.rows", rows);
        } catch (e) {
            alert("helpApplyDimensionFilter = " + e);
        }
    },

    /**
     * Details button
     * Button hides all simple report lines
     * @param cmp
     */
    helpShowHideSimpleRows: function (cmp) {
        _showSpinner(cmp);
        let _this = this;
        try {
            _showSpinner(cmp);
            if (cmp.get('v.showSimpleRows')) {
                //cmp.set('v.rows', cmp.get('v.rowsWithSimple'));
            } else {
                let rows = cmp.get('v.rows');
                let rowsWithoutSimple = [];
                for (let i = 0; i < rows.length; i++) {
                    if (rows[i].type === undefined) continue;
                    rowsWithoutSimple.push(rows[i]);
                }
                cmp.set('v.rows', rowsWithoutSimple);
                _hideSpinner(cmp);
            }
        } catch (e) {
            alert(e);
        }
    },

    helpApplyColumnsFilter: function (cmp) {
        _cl("helpApplyColumnsFilter", 'yellow');

        let i, j, groups;
        let indexToHide = []; //
        let hiddenColumns = []; //
        const columns = cmp.get("v.reportColumns");
        const numberOfTextColumns = cmp.get("v.numberOfTextColumns") - 0 + 1;
        const columnsOptions = cmp.get("v.columnsOptions");
        let displayedColumns = cmp.get("v.displayedColumns");
        const report = cmp.get("v.report");

        if (displayedColumns === undefined || displayedColumns == null || displayedColumns.length === 0) {
            try {
                displayedColumns = JSON.parse(report.cb4__DisplayedColumns__c);
                for (i = displayedColumns.length; i--;) displayedColumns[i] = displayedColumns[i].trim();
                cmp.set("v.displayedColumns", displayedColumns);
            } catch (e) {
                _cl(" report.cb4__DisplayedColumns__c = " + report.cb4__DisplayedColumns__c, 'RED');
            }
        }

        if (displayedColumns === undefined || displayedColumns == null || displayedColumns.length === 0) {
            _cl(" abnormal column settings", 'red ');
            return 0;
        }

        if (displayedColumns.length === columnsOptions.length) {
            _cl("All columns are displayed", 'green');
            _cl("DISPLAYED COLUMNS NUMBER IS " + displayedColumns.length, 'green');
            return 0;
        }

        for (i = displayedColumns.length; i--;) displayedColumns[i] = displayedColumns[i].trim();

        _cl(" columnsOptions = " + JSON.stringify(columnsOptions), 'ORANGE');
        _cl(" Report cb4__DisplayedColumns__c = " + report.cb4__DisplayedColumns__c, 'ORANGE');
        _cl(" displayedColumns = " + displayedColumns, 'ORANGE');
        _cl(" columns = " + JSON.stringify(columns), 'ORANGE');

        cmp.set("v.displayedColumns", displayedColumns);

        try {
            for (i = columnsOptions.length; i--;) if (!displayedColumns.includes(columnsOptions[i].value)) hiddenColumns.push(columnsOptions[i].value);

            for (i = 0; i < columns.length; i++) {
                let colDG = columns[i].cb4__DisplayGroup__c;
                if (_isInvalid(colDG)) continue;

                groups = colDG.split(','); // array from column titles
                let needToHide = false; // column need to hide flag
                for (j = groups.length; j--;) {
                    if (hiddenColumns.includes(groups[j].trim())) {
                        needToHide = true;
                        break;
                    }
                }
                if (needToHide) indexToHide.push(i);
            }

            let rows = cmp.get("v.rows");

            let newRowValues;
            for (i = rows.length; i--;) {
                newRowValues = [];
                for (j = 0; j < rows[i].v.length; j++) if (!indexToHide.includes(j)) newRowValues.push(rows[i].v[j]);
                rows[i].v = newRowValues;
            }

            newRowValues = [];
            let newColumnsValues = [];
            let tableHeaders = cmp.get("v.tableHeaders");

            j = 0;
            for (i = 0; i < tableHeaders.length; i++) {
                if (i < numberOfTextColumns - 1) { // text fields
                    newRowValues.push(tableHeaders[i]);
                    continue;
                }
                if (!indexToHide.includes(j)) newRowValues.push(tableHeaders[i]);
                j++
            }

            cmp.set("v.tableHeaders", newRowValues);

            for (i = 0; i < columns.length; i++) if (!indexToHide.includes(i)) newColumnsValues.push(columns[i]);
            cmp.set("v.reportColumns", newColumnsValues);

        } catch (err) {
            alert("ERROR helpApplyColumnsFilter = " + err);
        }
    }
    ,
    /////// HEADER FILTERS ///////

    /////// DATA TABLE ///////
    /**
     * jQuery DataTable lib applying
     */
    applyJQueryDataTable: function (cmp) {
        _cl("applyJQueryDataTable " + (cmp.get("v.fitPageEnabled") ? 'enabled' : 'disabled'), "yellow");

        if (!(cmp.get("v.fitPageEnabled"))) {
            _hideSpinner(cmp);
            cmp.set("v.showExportButtons", true);
            this.showHeaderAndTable(cmp);
            return 1;
        }

        let _this = this;

        if ($.fn.dataTable.isDataTable('#mt')) {
            let table = $('#mt').DataTable();
            table.destroy();
            $("#mt > tbody > .odd").remove();
        } else { // first run
        }

        window.setTimeout(
            $A.getCallback(function () {
                $(".trueHide").remove();

                try {
                    let fixedColumns = cmp.get("v.report.cb4__FixedColumns__c");
                    if (fixedColumns === null || fixedColumns === undefined) fixedColumns = 0;
                    const tableHeight = (window.innerHeight - 280) + "px";

                    let table = $("#mt").DataTable({
                        scrollY: tableHeight,
                        scrollX: true,
                        scrollCollapse: true,
                        paging: false,
                        fixedColumns: {
                            leftColumns: fixedColumns,
                        },
                        bSort: false,
                        deferRender: true,
                        bSortClasses: false,
                        scroller: true,
                        order: [],
                        "drawCallback": function (settings) {
                            _hideSpinner(cmp);
                            cmp.set("v.showExportButtons", true);
                            _this.showHeaderAndTable(cmp);
                        }
                    });

                } catch (e) {
                    alert("getCallback" + e);
                    _hideSpinner(cmp);
                }
            }), 10
        );
    }
    ,

    /**  DO NOT REMOVE. IT WILL HELP SOMEDAY
     * if ($.fn.dataTable.isDataTable('#mt')) {
                  let table = $('#mt').DataTable();
                  table.destroy();
                  $("#mt > tbody > .odd").remove();
              } else { // first run
              }

     console.log("HERE");
     let table = $("#mt").DataTable({
                  scrollX: true,
                  scrollCollapse: true,
                  paging: false,
                  bSort: false,
                  deferRender: true,
                  bSortClasses: false,
                  scroller: true,
                  order: [],
              });
     table.columns().visible(true, false);
     table.columns(indexToHide).visible(false, false);
     table.columns.adjust().draw(false); // adjust column sizing and redraw
     */

    /////// DATA TABLE ///////

    /////// EXCEL ///////
    helpDownloadAllToExcel: function (cmp) {
        _showSpinner(cmp);

        let _this = this;

        window.setTimeout(
            $A.getCallback(function () {

                try {
                    cmp.set("v.d1filter", null);
                    cmp.set("v.d2filter", null);
                    cmp.set("v.d3filter", null);
                    cmp.set("v.d4filter", null);
                    cmp.set("v.d5filter", null);
                    cmp.set("v.d6filter", null);
                    cmp.set("v.d7filter", null);
                    const maxNumber = cmp.get("v.report.cb4__MaxRowNumber__c");
                    cmp.set("v.report.cb4__MaxRowNumber__c", 1000000);
                    _this.helpRefreshReportData(cmp, true);

                    cmp.set("v.report.cb4__MaxRowNumber__c", maxNumber);
                    _this.helpRefreshReportData(cmp);

                } catch (e) {
                    alert("ERROR : " + e);

                }

            }, 10));
    },

    helpDownloadExcel: function (cmp) {
        try {
            let report = cmp.get("v.report");
            let tableRows = cmp.get('v.rows');

            let workbook = new ExcelJS.Workbook();
            let sheetName = report.Name;
            let fixedColumns = report.cb4__FixedColumns__c;
            if (_isInvalid(fixedColumns)) fixedColumns = 1; else fixedColumns--;
            let tableHeaders = cmp.get("v.tableHeaders");
            sheetName = sheetName.substring(0, 30).replace(':', '\uA789');
            let worksheet = workbook.addWorksheet(sheetName, {
                views: [
                    {state: 'frozen', ySplit: 1, xSplit: fixedColumns}
                ]
            });

            // COLUMNS
            let arr = [];
            tableHeaders.forEach(function (h) {
                //arr.push({header: h, key: h, width: 16, style: {numFmt: '$ #,##0.00;[Red]($ #,##0.00)'}});
                if(h === 'Actual vs Budget YTD') {
                    arr.push({header: h, key: h, width: 16, style: {numFmt: '#,##0.00;[Red](#,##0.00)'}});
                }else{
                    arr.push({header: h, key: h, width: 16, style: {numFmt: '#,##0.00;[Black](#,##0.00)'}});
                }
            });
            worksheet.columns = arr;
            // COLUMNS

            let subTotalRowNumbers = [];
            let i = 2;

            // ROWS
            const n = cmp.get("v.numberOfTextColumns"); // the number of text columns
            tableRows.forEach(function (row, idx) {
                if (row.type === 'subTotal1' || row.type === 'subTotal2' || row.type === 'subTotal3' || row.type === 'subTotal4') subTotalRowNumbers.push(i);
                i++;

                let r = {}; // one row
                for (let j = 0; j < n; j++) r[tableHeaders[j]] = row["l" + (j + 1) + "Long"];

                let k = n;
                row.v.forEach(function (val) {
                    r[tableHeaders[k]] = getRowAmount(val);
                    k++;
                });

                worksheet.addRow(r);
            });

            function getRowAmount(val) {
                if (val === '-') return val;
                if (val.includes(' %')) parseFloat(val.replace(' %').replace(/,/g, '')) + ' %';
                return parseFloat(val.replace(/,/g, ''));
            }

            // ROWS

            const borderStyles = {
                top: {style: "thin"},
                left: {style: "thin"},
                bottom: {style: "thin"},
                right: {style: "thin"}
            };
            const headerBorderStyles = {
                top: {style: "thin"},
                left: {style: "thin"},
                bottom: {style: 'double', color: {argb: '005493'}},
                right: {style: "thin"}
            };
            const headerFill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: {argb: '0080DF'}
            };
            const totalFill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: {argb: '16325c'}
            };
            worksheet.eachRow({includeEmpty: true}, function (row, rowNumber) { // all rows
                row.eachCell({includeEmpty: true}, function (cell, cellNumber) {
                    cell.border = borderStyles;
                    cell.font = {color: {argb: '4a4a4a'}};
                });
            });
            worksheet.getRow(1).eachCell({includeEmpty: false}, function (cell, cellNumber) { // table header
                cell.font = {bold: true, color: {argb: 'FFFFFF'},};
                cell.border = headerBorderStyles;
                cell.fill = headerFill;
            });

            subTotalRowNumbers.forEach(function (index) {
                worksheet.getRow(index).eachCell({includeEmpty: false}, function (cell, cellNumber) { // subtotal lines
                    cell.font = {bold: true};
                });
            });

            worksheet.getRow(2).eachCell({includeEmpty: false}, function (cell, cellNumber) { // Total
                cell.font = {bold: true, color: {argb: 'FFFFFF'}};
                cell.fill = totalFill;
            });

            // BOTTOM LINE
            worksheet.addRow([]);
            worksheet.addRow(['CloudBudget 2.0']);
            worksheet.addRow([new Date().toJSON().slice(0, 10).replace(/-/g, '/')]);

            workbook.xlsx.writeBuffer().then(buffer => saveAs(new Blob([buffer]), cmp.get('v.report.Name') + '.xlsx')).catch(err => alert('Error writing excel export', err));
        } catch (e) {
            alert(e);
        }
    },

    helpCreatePDF: function (cmp) {
        let form = $('.letter'),
            cache_width = form.width(),
            a4 = [595.28, 841.89]; // for a4 size paper width and height

        this.getCanvas().then(function (canvas) {
            let img = canvas.toDataURL("image/png"),
                doc = new jsPDF({
                    unit: 'mm',
                    format: 'a4'
                });
            doc.addImage(img, 'PNG', 0, 0); /*doc.addImage(img, 'JPEG', 50, 50);*/
            doc.save('Report.pdf');
            form.width(cache_width);
        });
    },

    getCanvas: function () {
        let form = $('.letter'),
            cache_width = form.width(),
            a4 = [595.28, 841.89];
        return html2canvas(form, {
            imageTimeout: 2000,
            removeContainer: true
        });
    },

    helpDownloadPDF: function (cmp) {
        try {

            let source = document.getElementById('tableToPDF');

            function removeElementsByClass(source, classNames) {
                classNames.forEach(className => {
                    let element = source.getElementsByClassName(className)[0];
                    if (element) element.className += ' slds-no-print';
                });
            }

            try {
                source.getElementsByClassName('dataTables_scrollHead')[0].style.overflow = '';
                source.getElementsByClassName('dataTables_scrollBody')[0].style.overflow = '';
                $(".total").addClass("PDFTotal");
                $(".index").addClass("PDFIndex");
                $(".sorting_disabled").addClass("PDFColumnTop");
            } catch (e) {
            }
            removeElementsByClass(source, ['DTFC_LeftWrapper', 'DTFC_RightWrapper', 'trueHide', 'dataTables_info', 'dataTables_filter']);
            document.getElementById('pdfHeader').className = document.getElementById('pdfHeader').className.replace(' slds-hide', '');
            window.print();
            document.getElementById('pdfHeader').className += ' slds-hide';

            try {
                source.getElementsByClassName('dataTables_scrollHead')[0].style.overflow = 'hidden';
                source.getElementsByClassName('dataTables_scrollBody')[0].style.overflow = 'auto';
                $(".total").removeClass("PDFTotal");
                $(".index").removeClass("PDFIndex");
                $(".sorting_disabled").removeClass("PDFColumnTop");
            } catch (e) {

            }

        } catch (e) {
            alert(e);
        }
    },

    /*getPDFTableHeaderConfigs: function (cmp, firstRow, attrHeaders) {
        // data format : [{name: 'col1data', prompt: 'Amount' , width: 70, align: 'right'}, {name: 'col2data', prompt: 'Quantity' , width: 70, align: 'right'}]
        function cutTo(text, num) {
            return text.length >= num ? text.slice(0, num) + '...' : text;
        }

        let tableHeaders = [...cmp.get(attrHeaders)];
        let configArr = [], firstDataCol = firstRow !== undefined ? firstRow : undefined;
        if (firstDataCol !== undefined) {
            tableHeaders.forEach((title, index) => {
                let name = Object.keys(firstDataCol)[index], al = name.match('rv') ? 'right' : 'left';
                let configObj = {
                    name: name,
                    prompt: name.match('rv') ? cutTo(title, 9) : cutTo(title, 19),
                    width: name.match('rv') ? 70 : 127,
                    align: al
                };
                configArr.push(configObj);
            });
        }
        return configArr;
    },*/

    /*getPDFTableData: function (cmp, attrRows) {
        // data format : [{"col1data": "10", "col2data":"20","col3data":"30"}, {"col1data": "10", "col2data":"20","col3data":"30"}]
        function cutTo(text, num) {
            return text.length >= num ? text.slice(0, num) + '...' : text;
        }

        let tableData = [...cmp.get(attrRows)], result = [];
        tableData.forEach(row => {
            let temp = {};
            if (row.l1 !== undefined) {
                temp.l1 = cutTo(row.l1, 30);
            }
            if (row.l2 !== undefined) {
                temp.l2 = cutTo(row.l2, 30);
            }
            if (row.l3 !== undefined) {
                temp.l3 = cutTo(row.l3, 30);
            }
            if (row.l4 !== undefined) {
                temp.l4 = cutTo(row.l4, 30);
            }
            if (row.l5 !== undefined) {
                temp.l5 = cutTo(row.l5, 30);
            }
            if (row.l6 !== undefined) {
                temp.l6 = cutTo(row.l6, 30);
            }
            if (row.l7 !== undefined) {
                temp.l7 = cutTo(row.l7, 30);
            }
            row.rowValues.forEach((value, index) => {
                temp['rv' + index] = value;
            });
            result.push(temp);
        });
        return result;
    },*/
    /////// EXCEL ///////

    /////// DRILL DOWN ///////
    helpGetDrillDown: function (cmp, key) {
        _showSpinner(cmp);

        window.setTimeout(
            $A.getCallback(function () {


                let drillDownName = cmp.get("v.report.cb4__DrillDownComponent__c"); // set in the helpGetDimension method
                if (_isInvalid(drillDownName)) {
                    _CBMessages.fireOtherMessage("DrillDown is not provided for this report");
                    _hideSpinner(cmp);
                    return null;
                }
                const ddColor = "#30d5c8";
                key = key.split('*');
                let columns = cmp.get('v.reportColumns');
                let balanceKey = key[0];
                let columnId = columns[key[1]].cb4__Column__c;
                _cl("columns idx = " + JSON.stringify(columns[key[1]]), ddColor);
                _cl('DrillDown: idx=' + key[1] + ' balanceKey=' + balanceKey + ' columnId=' + columnId, ddColor);

                if (_isInvalid(columnId) || _isInvalid(balanceKey) || balanceKey === 'undefined') {
                    _hideSpinner(cmp);
                    return 1;
                }

                cmp.set("v.drillDownComponent", []);// erase old component if it exists
                $A.createComponent(drillDownName.includes(':') ? drillDownName : 'cb4:' + drillDownName,
                    {
                        "CBalanceKey": balanceKey,
                        "columnId": columnId,
                        "reportId": cmp.get("v.report.Id")
                    },
                    function (drillDown, status, errorMessage) {
                        if (status === "SUCCESS") {
                            let newCmp = cmp.get("v.drillDownComponent");
                            newCmp.push(drillDown);
                            cmp.set("v.drillDownComponent", newCmp);
                        } else if (status === "INCOMPLETE") {
                        } else if (status === "ERROR") {
                            _CBMessages.fireErrorMessage("Drill Down Component failed to load " + errorMessage);
                        }
                        _hideSpinner(cmp);
                    }
                );

            }, 10));
    },
    /////// DRILL DOWN ///////

    helpGetReportWarningMessage: function (cmp) {
        if (cmp.get("v.reportMessage") != null) return true;
        const iconType = "action:announcement";
        let action = cmp.get("c.getLastUpdateMessageServer");
        action.setParams({
            "reportId": cmp.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                try {
                    cmp.set("v.reportMessage", "Ok");
                    let r = response.getReturnValue();
                    _cl("Warning Message:" + r, 'red');
                    if (r.length === 0) {
                        //_hideSpinner(cmp);
                        return true;
                    } // no warning message needed
                    let reportMessages = [];
                    reportMessages.push(_TEXT.REPORT.WARNING_MESSAGE_START);
                    reportMessages.push(_TEXT.REPORT.WARNING_MESSAGE_DATA + r[0]);
                    if (r.length > 1) reportMessages.push(_TEXT.REPORT.WARNING_MESSAGE_CBALANCES + r[1]);
                    reportMessages.push(_TEXT.REPORT.WARNING_MESSAGE_ADVICE);

                    this.helpShowModalDialog(cmp, reportMessages, iconType);
                } catch (e) {
                    alert(e);
                }
            } else {
                _CBMessages.fireErrorMessage('helpGetReportWarningMessage error');
            }
        });
        $A.enqueueAction(action);
    }
    ,
    helpShowModalDialog: function (cmp, reportMessages, iconType) {
        try {
            const orgPfx = 'cb4';
            $A.createComponent(orgPfx + ":ModalContent", {'strings': reportMessages, 'iconType': iconType},
                function (content, status) {
                    try {
                        if (status === "SUCCESS") {
                            reportMessages = content;
                            cmp.find('overlayLib').showCustomModal({
                                header: "Note",
                                body: reportMessages,
                                showCloseButton: true,
                                cssClass: "mymodal"
                            });
                            _hideSpinner(cmp);
                        }
                    } catch (e) {
                        alert(e);
                    }
                });
        } catch (e) {
            alert(e);
            _hideSpinner(cmp);
        }
    }
    ,

    helpShowExcelPanel: function (cmp) {
        let exPanel = $(cmp.find("excelPanel").getElement());
        if (exPanel.css('right') === '-420px') {
            exPanel.animate({right: '0', opacity: 1});
        } else {
            exPanel.animate({right: '-420px', opacity: 0.9});
        }
    }
    ,
    helpShowPDFPanel: function (cmp) {
        let pdfPanel = $(cmp.find("PDFPanel").getElement());
        if (pdfPanel.css('right') === '-250px') {
            pdfPanel.animate({right: '0', opacity: 1});
        } else {
            pdfPanel.animate({right: '-250px', opacity: 0.9});
        }
    }


});