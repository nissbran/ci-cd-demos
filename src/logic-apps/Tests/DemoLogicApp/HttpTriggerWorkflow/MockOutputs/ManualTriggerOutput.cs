using Microsoft.Azure.Workflows.UnitTesting.Definitions;
using Microsoft.Azure.Workflows.UnitTesting.ErrorResponses;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Collections.Generic;
using System.Net;
using System;

namespace DemoLogicApp.Tests.Mocks.HttpTriggerWorkflow
{
    /// <summary>
    /// The <see cref="ManualTriggerMock"/> class.
    /// </summary>
    public class ManualTriggerMock : TriggerMock
    {
        /// <summary>
        /// Creates a mocked instance for  <see cref="ManualTriggerMock"/> with static outputs.
        /// </summary>
        public ManualTriggerMock(TestWorkflowStatus status = TestWorkflowStatus.Succeeded, string name = null, ManualTriggerOutput outputs = null)
            : base(status: status, name: name, outputs: outputs ?? new ManualTriggerOutput())
        {
        }

        /// <summary>
        /// Creates a mocked instance for  <see cref="ManualTriggerMock"/> with static error info.
        /// </summary>
        public ManualTriggerMock(TestWorkflowStatus status, string name = null, TestErrorInfo error = null)
            : base(status: status, name: name, error: error)
        {
        }

        /// <summary>
        /// Creates a mocked instance for <see cref="ManualTriggerMock"/> with a callback function for dynamic outputs.
        /// </summary>
        public ManualTriggerMock(Func<TestExecutionContext, ManualTriggerMock> onGetTriggerMock, string name = null)
            : base(onGetTriggerMock: onGetTriggerMock, name: name)
        {
        }
    }

    /// <summary>
    /// Class for ManualTriggerOutput representing an object with properties.
    /// </summary>
    public class ManualTriggerOutput : MockOutput
    {
        public HttpStatusCode StatusCode {get; set;}

        public JObject Body { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="ManualTriggerOutput"/> class.
        /// </summary>
        public ManualTriggerOutput()
        {
            this.StatusCode = HttpStatusCode.OK;
            this.Body = new JObject();
        }
    }
}