using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Azure.Workflows.UnitTesting.Definitions;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using DemoLogicApp.Tests.Mocks.HttpTriggerWorkflow;

namespace DemoLogicApp.Tests
{
    /// <summary>
    /// The unit test class.
    /// </summary>
    [TestClass]
    public class Test
    {
        /// <summary>
        /// The unit test executor.
        /// </summary>
        public TestExecutor TestExecutor;

        [TestInitialize]
        public void Setup()
        {
            this.TestExecutor = new TestExecutor("HttpTriggerWorkflow/testSettings.config");
        }

        /// <summary>
        /// A sample unit test for executing the workflow named HttpTriggerWorkflow with static mocked data.
        /// This method shows how to set up mock data, execute the workflow, and assert the outcome.
        /// </summary>
        [TestMethod]
        public async Task HttpTriggerWorkflow_Test_ExecuteWorkflow_SUCCESS_Sample1()
        {
            // PREPARE Mock
            // Generate mock trigger data.
            var triggerMockOutput = new ManualTriggerOutput();
            // Sample of how to set the properties of the triggerMockOutput
            // triggerMockOutput.Body.Id = "SampleId";
            var triggerMock = new ManualTriggerMock(outputs: triggerMockOutput);

            // ACT
            // Create an instance of UnitTestExecutor, and run the workflow with the mock data.
            var testMock = new TestMockDefinition(
                triggerMock: triggerMock,
                actionMocks: null);
            var testRun = await this.TestExecutor
                .Create()
                .RunWorkflowAsync(testMock: testMock).ConfigureAwait(continueOnCapturedContext: false);

            // ASSERT
            // Verify that the workflow executed successfully, and the status is 'Succeeded'.
            Assert.IsNotNull(value: testRun);
            Assert.AreEqual(expected: TestWorkflowStatus.Succeeded, actual: testRun.Status);
        }
    }
}