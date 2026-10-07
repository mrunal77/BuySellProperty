using System.Text.Json;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddPropertyDetails : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "contact_name",
                schema: "properties",
                table: "properties",
                type: "character varying(120)",
                maxLength: 120,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "contact_phone",
                schema: "properties",
                table: "properties",
                type: "character varying(30)",
                maxLength: 30,
                nullable: true);

            migrationBuilder.AddColumn<JsonElement>(
                name: "details",
                schema: "properties",
                table: "properties",
                type: "jsonb",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "whatsapp",
                schema: "properties",
                table: "properties",
                type: "character varying(30)",
                maxLength: 30,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "contact_name",
                schema: "properties",
                table: "properties");

            migrationBuilder.DropColumn(
                name: "contact_phone",
                schema: "properties",
                table: "properties");

            migrationBuilder.DropColumn(
                name: "details",
                schema: "properties",
                table: "properties");

            migrationBuilder.DropColumn(
                name: "whatsapp",
                schema: "properties",
                table: "properties");
        }
    }
}
