function Convert-TestResultToNunitResult
{
    param(
        $TrxFile
    )    

    function ParseTimeSpan ($NAVTimeSpan) {
        $Parts = $NAVTimeSpan.Split('PYMDTHMS')
        return [Timespan]($Parts[3]+":"+$Parts[5]+":"+ $Parts[6]+":"+$Parts[7])
    }

    $OutFile = Split-Path $TrxFile -Leaf
    $FileNo = 0
    $TestResults = [xml]('<?xml version="1.0" encoding="utf-8" standalone="no"?>'+
        '<TestRun>'+
        "<TestRunConfiguration name=`"NAV Automati Test Run`">"+
        '<Description>This is a default test run configuration for a local test run.</Description>'+
        '<TestTypeSpecific /></TestRunConfiguration>'+
        '<ResultSummary outcome="Passed">'+
        '<Counters total="0" executed="0" passed="0" error="0" failed="0" timeout="0" aborted="0" inconclusive="0" passedButRunAborted="0" notRunnable="0" notExecuted="0" disconnected="0" warning="0" completed="0" inProgress="0" pending="0" />'+
        '</ResultSummary>'+
        "<Times creation=`"$(Get-Date -Format o)`" queuing=`"$(Get-Date -Format o)`" start=`"`" finish=`"`" />"+
        '<TestSettings id="010e155f-ff0f-44f5-a83e-5093c2e8dcc4" name="Settings">'+
        '</TestSettings>'+
        '<TestDefinitions></TestDefinitions>'+
        '<TestLists>'+
        '<TestList name="Results Not in a List" id="8c84fa94-04c1-424b-9868-57a2d4851a1d" />'+
        '<TestList name="All Loaded Results" id="19431567-8539-422a-85d7-44ee4e166bda" />'+
        '</TestLists>'+
        '<TestEntries></TestEntries>'+
        '<Results></Results>'+
    '</TestRun>')
    $TestRun = $TestResults.SelectSingleNode('/TestRun')
    $TestRun.SetAttribute('name','NAV Tests')
    $TestRun.SetAttribute('xmlns','http://microsoft.com/schemas/VisualStudio/TeamTest/2010')
    $TestRunConfig=$TestResults.SelectSingleNode('/TestRun/TestRunConfiguration')
    $configid = [guid]::NewGuid() -replace '{}',''
    $TestRunConfig.SetAttribute('id',$configid)
    $testrunid = [guid]::NewGuid() -replace '{}',''
    $TestRun.SetAttribute('id',$testrunid)
    $TestDefinitions=$TestResults.SelectSingleNode('/TestRun/TestDefinitions')
    $TestEntries=$TestResults.SelectSingleNode('/TestRun/TestEntries')
    $Results = $TestResults.SelectSingleNode('/TestRun/Results')
    $ResultsSummary = $TestResults.SelectSingleNode('/TestRun/ResultSummary')                                              
    $Times = $TestResults.SelectNodes('/TestRun/Times')

    foreach ($i in $input) {
        $TestSuiteName = $i.Codeunit_Name
        $TestDefinition = $TestResults.CreateElement('UnitTest')
        $null = $TestDefinitions.AppendChild($TestDefinition)
        $id = [guid]::NewGuid() -replace '{}',''
        $FunctionName=$i.Codeunit_ID.ToString()+':'+$i.Function_Name
        $TestDefinition.SetAttribute('name',$FunctionName)
        $TestDefinition.SetAttribute('id',$id)
        $TestDefinition.SetAttribute('storage',"$OutFile")
        $executionid= [guid]::NewGuid() -replace '{}',''
        $Execution = $TestResults.CreateElement('Execution')
        $null = $TestDefinition.AppendChild($Execution)
        $Execution.SetAttribute('id',$executionid)
        $TestMethod = $TestResults.CreateElement('TestMethod')
        $null = $TestDefinition.AppendChild($TestMethod)
        $TestMethod.SetAttribute('codeBase','COD'+$i.Codeunit_ID.ToString()+'.txt')
        $TestMethod.SetAttribute('className',$TestSuiteName)
        $TestMethod.SetAttribute('name',$FunctionName)
        $TestEntry = $TestResults.CreateElement('TestEntry')
        $null = $TestEntries.AppendChild($TestEntry)
        $TestEntry.SetAttribute('testId',$id)
        $TestEntry.SetAttribute('executionId',$executionid)
        $TestEntry.SetAttribute('testListId','8c84fa94-04c1-424b-9868-57a2d4851a1d')
        $Result = $TestResults.CreateElement('UnitTestResult')
        $null = $Results.AppendChild($Result)
        $Result.SetAttribute('executionId',$executionid)
        $Result.SetAttribute('testId',$id)
        $Result.SetAttribute('testName',$FunctionName)
        $Result.SetAttribute('computerName',$env:COMPUTERNAME)
        $Duration = ParseTimeSpan($i.Execution_Time)
        if ($Duration -lt 0) 
        {
            $Duration = -$Duration
        }
        $RunTime = $Duration #[TimeSpan]::FromMilliseconds(
        $Result.SetAttribute('duration',$RunTime.ToString());
        $StartTime = $i.Start_Time
        $EndTime = $i.Start_Time + $RunTime
        $Result.SetAttribute('startTime',$StartTime.ToString('O'))
        $Result.SetAttribute('endTime',$EndTime.ToString('O'))
        #Passed,Failed,Inconclusive,Incomplete
        $ResultsSummary.Counters.executed = (1+$ResultsSummary.Counters.executed).ToString()
        $ResultsSummary.Counters.total = (1+$ResultsSummary.Counters.total).ToString()
        if ($Times.GetAttribute('start') -eq '') {
            $Times.SetAttribute('start',$StartTime.ToString('O'))
        }
        $Times.SetAttribute('finish',$EndTime.ToString('O'))
        
        switch ($i.Result) {
            'Passed' 
            {
                $TestResult = 'Passed'
                $ResultsSummary.Counters.completed = (1+$ResultsSummary.Counters.completed).ToString()
                $ResultsSummary.Counters.passed = (1+$ResultsSummary.Counters.passed).ToString()
                $ResultsSummary.SetAttribute('outcome','Passed')
            }
            'Failed' 
            {
                $TestResult = 'Failed'
                $ResultsSummary.Counters.completed = (1+$ResultsSummary.Counters.completed).ToString()
                $ResultsSummary.Counters.failed = (1+$ResultsSummary.Counters.failed).ToString()
                $Output = $TestResults.CreateElement('Output')
                $null = $Result.AppendChild($Output)
                $ErrorInfo = $TestResults.CreateElement('ErrorInfo')
                $null = $Output.AppendChild($ErrorInfo)
                $Message = $TestResults.CreateElement('Message')
                $null = $ErrorInfo.AppendChild($Message)
                $Message.InnerText = $i.Error_Message
                #if ($line['Call Stack'] -and ($line['Call Stack'].ToString() -gt '')) {
                #    $CallStackData = Get-NAVBlobToString -CompressedByteArray $line['Call Stack'] -ErrorAction SilentlyContinue
                #    if ($CallStackData.Data)  {
                #        $StackTrace = $TestResults.CreateElement('StackTrace')
                #        $null = $ErrorInfo.AppendChild($StackTrace)
                #        $StackTrace.InnerText = $CallStackData.Data
                #    }
                #}
                $ResultsSummary.SetAttribute('outcome','Failed')
            }
            'Inconclusive'
            {
                $TestResult = 'Inconclusive'
                $ResultsSummary.Counters.completed = (1+$ResultsSummary.Counters.completed).ToString()
                $ResultsSummary.Counters.inconclusive = (1+$ResultsSummary.Counters.inconclusive).ToString()
            }
            'Incomplete' 
            {
                #$TestResult = 'Incomplete'
                $TestResult = 'inProgress'
            }
        }
        $Result.SetAttribute('outcome',$TestResult)
        $Result.SetAttribute('testListId','8c84fa94-04c1-424b-9868-57a2d4851a1d')
        $Result.SetAttribute('testType','13cdc9d9-ddb5-4fa4-a97d-d965ccfc6d4b')
    }
    Write-Host "Saving test results to $TrxFile (current working folder is $(Get-Location))"
    $TestResults.Save($TrxFile)
    Write-Output $TestResults
}