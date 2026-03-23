using Microsoft.Azure.Workflows.UnitTesting.Definitions;
using Microsoft.Azure.Workflows.UnitTesting.ErrorResponses;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Collections.Generic;
using System.Net;
using System;

namespace DemoLogicApp.Tests.Mocks.ReceiveOrderWorkflow
{
    /// <summary>
    /// The <see cref="SendToOrdersinternalActionMock"/> class.
    /// </summary>
    public class SendToOrdersinternalActionMock : ActionMock
    {
        /// <summary>
        /// Creates a mocked instance for  <see cref="SendToOrdersinternalActionMock"/> with static outputs.
        /// </summary>
        public SendToOrdersinternalActionMock(TestWorkflowStatus status = TestWorkflowStatus.Succeeded, string name = null, SendToOrdersinternalActionOutput outputs = null)
            : base(status: status, name: name, outputs: outputs ?? new SendToOrdersinternalActionOutput())
        {
        }

        /// <summary>
        /// Creates a mocked instance for  <see cref="SendToOrdersinternalActionMock"/> with static error info.
        /// </summary>
        public SendToOrdersinternalActionMock(TestWorkflowStatus status, string name = null, TestErrorInfo error = null)
            : base(status: status, name: name, error: error)
        {
        }

        /// <summary>
        /// Creates a mocked instance for <see cref="SendToOrdersinternalActionMock"/> with a callback function for dynamic outputs.
        /// </summary>
        public SendToOrdersinternalActionMock(Func<TestExecutionContext, SendToOrdersinternalActionMock> onGetActionMock, string name = null)
            : base(onGetActionMock: onGetActionMock, name: name)
        {
        }
    }

    /// <summary>
    /// Class for SendToOrdersinternalActionOutput representing an empty object.
    /// </summary>
    public class SendToOrdersinternalActionOutput : MockOutput
    {
        public HttpStatusCode StatusCode {get; set;}

        /// <summary>
        /// Initializes a new instance of the <see cref="SendToOrdersinternalActionOutput"/> class.
        /// </summary>
        public SendToOrdersinternalActionOutput()
        {
            this.StatusCode = HttpStatusCode.OK;
        }
    }
}