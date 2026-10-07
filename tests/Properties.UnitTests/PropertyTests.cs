using FluentAssertions;
using Properties.Domain;

namespace Properties.UnitTests;

public sealed class PropertyTests
{
    [Fact]
    public void Create_rejects_non_positive_price()
    {
        var r = Property.Create("Nice 2BHK", "desc", PropertyType.Apartment, ListingType.Sale,
            0, 1000, Guid.NewGuid(), "addr", Guid.NewGuid(), 18.5, 73.8);
        r.IsFailure.Should().BeTrue();
        r.Error!.Code.Should().Be("property.invalid_price");
    }

    [Fact]
    public void Create_rejects_invalid_geo()
    {
        var r = Property.Create("Nice 2BHK", "desc", PropertyType.Apartment, ListingType.Sale,
            5000000, 1000, Guid.NewGuid(), "addr", Guid.NewGuid(), 999, 999);
        r.IsFailure.Should().BeTrue();
    }

    [Fact]
    public void Publish_sets_active_and_timestamp()
    {
        var r = Property.Create("Nice 2BHK", "desc", PropertyType.Apartment, ListingType.Sale,
            5000000, 1000, Guid.NewGuid(), "addr", Guid.NewGuid(), 18.5, 73.8);
        r.IsSuccess.Should().BeTrue();
        var p = r.Value!;
        p.Status.Should().Be(PropertyStatus.Draft);
        p.Publish().IsSuccess.Should().BeTrue();
        p.Status.Should().Be(PropertyStatus.Active);
        p.PublishedAt.Should().NotBeNull();
    }

    [Fact]
    public void Pause_requires_active()
    {
        var r = Property.Create("Plot", "desc", PropertyType.Plot, ListingType.Sale,
            2000000, 2000, Guid.NewGuid(), "addr", Guid.NewGuid(), 18.5, 73.8).Value!;
        r.Pause().IsFailure.Should().BeTrue(); // Draft -> cannot pause
        r.Publish();
        r.Pause().IsSuccess.Should().BeTrue();
    }

    [Fact]
    public void IsOwnedBy_checks_owner()
    {
        var owner = Guid.NewGuid();
        var p = Property.Create("Villa", "desc", PropertyType.Villa, ListingType.Sale,
            9000000, 2500, owner, "addr", Guid.NewGuid(), 18.5, 73.8).Value!;
        p.IsOwnedBy(owner).Should().BeTrue();
        p.IsOwnedBy(Guid.NewGuid()).Should().BeFalse();
    }

    private static Property Make(PropertyStatus status)
    {
        var p = Property.Create("T", "d", PropertyType.Apartment, ListingType.Sale,
            5000000, 1000, Guid.NewGuid(), "addr", Guid.NewGuid(), 18.5, 73.8).Value!;
        if (status == PropertyStatus.Active) p.Publish();
        else if (status == PropertyStatus.Paused) { p.Publish(); p.Pause(); }
        else if (status == PropertyStatus.Sold) p.MarkSold();
        else if (status == PropertyStatus.Rented) p.MarkRented();
        else if (status == PropertyStatus.Rejected) p.Reject("test");
        return p;
    }

    [Theory]
    [InlineData(PropertyStatus.Draft)]
    [InlineData(PropertyStatus.Active)]
    [InlineData(PropertyStatus.Paused)]
    [InlineData(PropertyStatus.Expired)]
    [InlineData(PropertyStatus.Rejected)]
    public void MarkSold_allowed_from_open_statuses(PropertyStatus from)
    {
        var p = Make(from);
        p.MarkSold().IsSuccess.Should().BeTrue();
        p.Status.Should().Be(PropertyStatus.Sold);
    }

    [Fact]
    public void MarkSold_rejects_when_already_sold()
    {
        var p = Make(PropertyStatus.Sold);
        var r = p.MarkSold();
        r.IsFailure.Should().BeTrue();
        r.Error!.Code.Should().Be("property.already_closed");
        p.Status.Should().Be(PropertyStatus.Sold);
    }

    [Fact]
    public void MarkSold_rejects_when_rented()
    {
        var p = Make(PropertyStatus.Rented);
        var r = p.MarkSold();
        r.IsFailure.Should().BeTrue();
        r.Error!.Code.Should().Be("property.invalid_transition");
        p.Status.Should().Be(PropertyStatus.Rented);
    }

    [Theory]
    [InlineData(PropertyStatus.Draft)]
    [InlineData(PropertyStatus.Active)]
    [InlineData(PropertyStatus.Paused)]
    [InlineData(PropertyStatus.Expired)]
    [InlineData(PropertyStatus.Rejected)]
    public void MarkRented_allowed_from_open_statuses(PropertyStatus from)
    {
        var p = Make(from);
        p.MarkRented().IsSuccess.Should().BeTrue();
        p.Status.Should().Be(PropertyStatus.Rented);
    }

    [Fact]
    public void MarkRented_rejects_when_already_rented()
    {
        var p = Make(PropertyStatus.Rented);
        var r = p.MarkRented();
        r.IsFailure.Should().BeTrue();
        r.Error!.Code.Should().Be("property.already_closed");
        p.Status.Should().Be(PropertyStatus.Rented);
    }

    [Fact]
    public void MarkRented_rejects_when_sold()
    {
        var p = Make(PropertyStatus.Sold);
        var r = p.MarkRented();
        r.IsFailure.Should().BeTrue();
        r.Error!.Code.Should().Be("property.invalid_transition");
        p.Status.Should().Be(PropertyStatus.Sold);
    }

    [Fact]
    public void Publish_blocked_after_sold()
    {
        var p = Make(PropertyStatus.Sold);
        var r = p.Publish();
        r.IsFailure.Should().BeTrue();
        r.Error!.Code.Should().Be("property.already_closed");
        p.Status.Should().Be(PropertyStatus.Sold);
    }

    [Fact]
    public void Publish_blocked_after_rented()
    {
        var p = Make(PropertyStatus.Rented);
        var r = p.Publish();
        r.IsFailure.Should().BeTrue();
        r.Error!.Code.Should().Be("property.already_closed");
        p.Status.Should().Be(PropertyStatus.Rented);
    }

    [Fact]
    public void Reject_sets_status_and_reason()
    {
        var p = Make(PropertyStatus.Active);
        p.Reject("spam listing").IsSuccess.Should().BeTrue();
        p.Status.Should().Be(PropertyStatus.Rejected);
        p.RejectionReason.Should().Be("spam listing");
    }

    [Fact]
    public void Sold_then_republish_blocked()
    {
        var p = Make(PropertyStatus.Active);
        p.MarkSold().IsSuccess.Should().BeTrue();
        p.Publish().IsFailure.Should().BeTrue();
        p.Status.Should().Be(PropertyStatus.Sold);
    }
}
