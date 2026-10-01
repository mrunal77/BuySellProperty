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
}
