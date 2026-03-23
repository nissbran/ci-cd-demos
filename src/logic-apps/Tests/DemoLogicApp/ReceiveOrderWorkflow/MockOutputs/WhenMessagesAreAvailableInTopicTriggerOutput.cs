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
    /// The <see cref="WhenMessagesAreAvailableInTopicTriggerMock"/> class.
    /// </summary>
    public class WhenMessagesAreAvailableInTopicTriggerMock : TriggerMock
    {
        /// <summary>
        /// Creates a mocked instance for  <see cref="WhenMessagesAreAvailableInTopicTriggerMock"/> with static outputs.
        /// </summary>
        public WhenMessagesAreAvailableInTopicTriggerMock(TestWorkflowStatus status = TestWorkflowStatus.Succeeded, string name = null, WhenMessagesAreAvailableInTopicTriggerOutput outputs = null)
            : base(status: status, name: name, outputs: outputs ?? new WhenMessagesAreAvailableInTopicTriggerOutput())
        {
        }

        /// <summary>
        /// Creates a mocked instance for  <see cref="WhenMessagesAreAvailableInTopicTriggerMock"/> with static error info.
        /// </summary>
        public WhenMessagesAreAvailableInTopicTriggerMock(TestWorkflowStatus status, string name = null, TestErrorInfo error = null)
            : base(status: status, name: name, error: error)
        {
        }

        /// <summary>
        /// Creates a mocked instance for <see cref="WhenMessagesAreAvailableInTopicTriggerMock"/> with a callback function for dynamic outputs.
        /// </summary>
        public WhenMessagesAreAvailableInTopicTriggerMock(Func<TestExecutionContext, WhenMessagesAreAvailableInTopicTriggerMock> onGetTriggerMock, string name = null)
            : base(onGetTriggerMock: onGetTriggerMock, name: name)
        {
        }
    }

    /// <summary>
    /// Class for WhenMessagesAreAvailableInTopicTriggerOutput representing an object with properties.
    /// </summary>
    public class WhenMessagesAreAvailableInTopicTriggerOutput : MockOutput
    {
        public HttpStatusCode StatusCode {get; set;}

        /// <summary>
        /// One or more messages received from Service Bus topic
        /// </summary>
        public List<BodyItem> Body { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="WhenMessagesAreAvailableInTopicTriggerOutput"/> class.
        /// </summary>
        public WhenMessagesAreAvailableInTopicTriggerOutput()
        {
            this.StatusCode = HttpStatusCode.OK;
            this.Body = new List<BodyItem>();
        }
    }
    /// <summary>
    /// Class for BodyItem representing an object with properties.
    /// </summary>
    public class BodyItem
    {
        /// <summary>
        /// Content of the message.
        /// </summary>
        public JObject ContentData { get; set; }

        /// <summary>
        /// The content type of the message.
        /// </summary>
        public string ContentType { get; set; }

        /// <summary>
        /// The identifier of the session.
        /// </summary>
        public string SessionId { get; set; }

        /// <summary>
        /// Any key-value pairs for user properties.
        /// </summary>
        public JObject UserProperties { get; set; }

        /// <summary>
        /// A user-defined value that Service Bus can use to identify duplicate messages, if enabled.
        /// </summary>
        public string MessageId { get; set; }

        /// <summary>
        /// The lock token is a reference to the lock that is being held by the broker in peek-lock receive mode.
        /// </summary>
        public string LockToken { get; set; }

        /// <summary>
        /// Sends to address
        /// </summary>
        public string To { get; set; }

        /// <summary>
        /// The address where to send a reply.
        /// </summary>
        public string ReplyTo { get; set; }

        /// <summary>
        /// The identifier of the session where to reply.
        /// </summary>
        public string ReplyToSession { get; set; }

        /// <summary>
        /// Application specific label
        /// </summary>
        public string Label { get; set; }

        /// <summary>
        /// The UTC date and time for when to add the message to the queue.
        /// </summary>
        public string ScheduledEnqueueTimeUtc { get; set; }

        /// <summary>
        /// The identifier of the correlation.
        /// </summary>
        public string CorrelationId { get; set; }

        /// <summary>
        /// The number of ticks or duration for when a message is valid. The duration starts from when the message is sent to Service Bus.
        /// </summary>
        public string TimeToLive { get; set; }

        /// <summary>
        /// Only set in messages that have been dead-lettered and later autoforwarded from the dead-letter queue to another entity. Indicates the entity in which the message was dead-lettered.
        /// </summary>
        public string DeadletterSource { get; set; }

        /// <summary>
        /// Number of deliveries that have been attempted for this message. The count is incremented when a message lock expires, or the message is explicitly abandoned by the receiver.
        /// </summary>
        public int DeliveryCount { get; set; }

        /// <summary>
        /// For messages that have been autoforwarded, this property reflects the sequence number that had first been assigned to the message at its original point of submission.
        /// </summary>
        public string EnqueuedSequenceNumber { get; set; }

        /// <summary>
        /// The UTC instant at which the message has been accepted and stored in the entity.
        /// </summary>
        public string EnqueuedTimeUtc { get; set; }

        /// <summary>
        /// For messages retrieved under a lock (peek-lock receive mode, not pre-settled) this property reflects the UTC instant until which the message is held locked in the queue/subscription.
        /// </summary>
        public string LockedUntilUtc { get; set; }

        /// <summary>
        /// The sequence number is a unique 64-bit integer assigned to a message as it is accepted and stored by the broker and functions as its true identifier.
        /// </summary>
        public string SequenceNumber { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="BodyItem"/> class.
        /// </summary>
        public BodyItem()
        {
            this.ContentData = new JObject();
            this.ContentType = string.Empty;
            this.SessionId = string.Empty;
            this.UserProperties = new JObject();
            this.MessageId = string.Empty;
            this.LockToken = string.Empty;
            this.To = string.Empty;
            this.ReplyTo = string.Empty;
            this.ReplyToSession = string.Empty;
            this.Label = string.Empty;
            this.ScheduledEnqueueTimeUtc = string.Empty;
            this.CorrelationId = string.Empty;
            this.TimeToLive = string.Empty;
            this.DeadletterSource = string.Empty;
            this.DeliveryCount = 0;
            this.EnqueuedSequenceNumber = string.Empty;
            this.EnqueuedTimeUtc = string.Empty;
            this.LockedUntilUtc = string.Empty;
            this.SequenceNumber = string.Empty;
        }
    }
}