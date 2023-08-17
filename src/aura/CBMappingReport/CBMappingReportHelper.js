({
    helpGetReportData: function (cmp) {
        const params = {
            type: cmp.get('v.type'),
            yearNumber: cmp.get('v.yearNumber'),
        };
        _cl('PARAMS:' + JSON.stringify(params), 'gold');
        function callback() {
            let reportData = cmp.get("v.reportData");
            let yearNumber = cmp.get("v.yearNumber");
            let yearsSO = reportData.yearsSO;
            if (_isInvalid(yearNumber) && !_isInvalid(yearsSO) && yearsSO.length > 0) cmp.set("v.yearNumber", yearsSO[0].value);
        }
        _CBRequest(cmp, "c.getReportDataServer", params, "v.reportData", callback, 'Loaded', 'Failed', true);
    },

    searchReportingDepartments: function (cmp) {
        let _this = this;

        function showResult() {
            let result = cmp.get("v.searchResult");
            if (result == null || result.length === 0) {
                alert('No reporting departments were found');
                return null;
            }

            let str = 'Searching results:\r\n';
            result.forEach(function (item) {

                str += item.Reporting_Department_Level__c + ': ' + item.Budget_Reporting_Department__r.Name + ' \r\n';
                str += ' DIMENSIONS: ' + item.Dimension_1__r.Name + ' & ' + item.Dimension_2__r.Name + ') ' + ' \r\n';
                str += ' *** ' + ' \r\n';

            });
            alert(str);

        }

        _CBRequest(cmp, "c.searchReportingDepartmentsServer", {
            dim1Name: cmp.get("v.dimension1"),
            dim2Name: cmp.get("v.dimension2")
        }, "v.searchResult", showResult, null, 'Failed', true);
    }
});