using System;
using System.Threading;
using Microsoft.VisualStudio.TestTools.UnitTesting;

[TestClass]
public class Tests
{
    [TestMethod]
    public void Passes() { }

    [TestMethod]
    public void Fails() => Assert.AreEqual(1, 2); // demo: project

    [TestMethod] // demo: project
    [Ignore("Skipped on purpose: the GitHub Actions report should annotate skipped tests")]
    public void Skipped() { }

    [TestMethod]
    public void Slow() => Thread.Sleep(TimeSpan.FromSeconds(3));
}
