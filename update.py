#!/usr/bin/env python

import os
import zipfile
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.panel import Panel
from rich import print as rprint

app = typer.Typer(
    name="ROMVault Updater",
    help="Build and manage ROMVault Docker images",
    add_completion=False,
)
console = Console()

DOCKER_VERSION = "1.0.3"


def open_template() -> str:
    """Read the Dockerfile template."""
    try:
        with open('Dockerfile.template') as f:
            return f.read()
    except FileNotFoundError:
        console.print("[red]❌ Error: Dockerfile.template not found[/red]")
        raise typer.Exit(1)


def save(template: str) -> None:
    """Save the processed template to Dockerfile."""
    with open('Dockerfile', 'w') as f:
        f.write(template)
    console.print("[green]✓[/green] Dockerfile saved")


def docker_build(docker_version: str, version: str) -> None:
    """Build Docker image."""
    tag = f'laromicas/romvault:v{docker_version}-{version}'
    console.print(f"\n[bold blue]🐳 Building Docker image:[/bold blue] [cyan]{tag}[/cyan]")

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console,
    ) as progress:
        task = progress.add_task("Building...", total=None)
        result = os.system(f'docker build . -t {tag}')
        progress.update(task, completed=True)

    if result == 0:
        console.print("[green]✓ Build completed successfully[/green]")
    else:
        console.print("[red]❌ Build failed[/red]")
        raise typer.Exit(1)


def docker_run(docker_version: str, version: str) -> None:
    """Run Docker container."""
    tag = f'laromicas/romvault:v{docker_version}-{version}'
    console.print(f"\n[bold blue]🚀 Running Docker container:[/bold blue] [cyan]{tag}[/cyan]")
    console.print("[yellow]📡 Port 5800 exposed[/yellow]")
    # os.system(f'docker run --rm -p 5800:5800 {tag}')
    os.system(f'docker run --rm -p 5800:5800 -e IONICE_CLASS=2 -e IONICE_LEVEL=7 {tag}')


def docker_push(docker_version: str, version: str, tag_latest: bool = False) -> None:
    """Push Docker image to registry."""
    tag = f'laromicas/romvault:v{docker_version}-{version}'
    console.print(Panel(
        f"[bold cyan]{tag}[/bold cyan]",
        title="[bold yellow]📤 Pushing to Docker Hub[/bold yellow]",
        border_style="yellow"
    ))
    result = os.system(f'docker push {tag}')

    if result == 0:
        console.print("[green]✓ Push completed successfully[/green]")
    else:
        console.print("[red]❌ Push failed[/red]")
        raise typer.Exit(1)

    if tag_latest:
        latest_tag = 'laromicas/romvault:latest'
        console.print(f"\n[bold blue]🏷️  Tagging as latest:[/bold blue] [cyan]{latest_tag}[/cyan]")
        result = os.system(f'docker tag {tag} {latest_tag}')
        if result != 0:
            console.print("[red]❌ Tagging failed[/red]")
            raise typer.Exit(1)

        console.print(Panel(
            f"[bold cyan]{latest_tag}[/bold cyan]",
            title="[bold yellow]📤 Pushing latest tag to Docker Hub[/bold yellow]",
            border_style="yellow"
        ))
        result = os.system(f'docker push {latest_tag}')
        if result == 0:
            console.print("[green]✓ Latest tag pushed successfully[/green]")
        else:
            console.print("[red]❌ Latest push failed[/red]")
            raise typer.Exit(1)


def compress(version: str) -> None:
    """Compress ROMVault executable."""
    zip_name = f'ROMVault{version}.zip'
    exe_name = 'ROMVault37.exe'

    if not Path(exe_name).exists():
        console.print(f"[yellow]⚠ Warning: {exe_name} not found, skipping compression[/yellow]")
        return

    console.print(f"[bold blue]📦 Compressing:[/bold blue] [cyan]{zip_name}[/cyan]")
    with zipfile.ZipFile(zip_name, 'w') as z:
        z.write(exe_name)
    console.print("[green]✓[/green] Compression completed")


@app.command()
def build(
    version: str = typer.Argument(..., help="Version number (e.g., 3.7.1)"),
    wip: Optional[str] = typer.Option(None, "--wip", "-w", help="WIP number (optional)"),
    push: bool = typer.Option(False, "--push", "-p", help="Push to Docker Hub instead of building"),
    tag_latest: bool = typer.Option(False, "--tag-latest", "-l", help="Tag and push as latest (only with --push)"),
    docker_version: str = typer.Option(DOCKER_VERSION, "--docker-version", "-d", help="Docker image version"),
    build: bool = typer.Option(True, "--build/--no-build", "-b", help="Build the Docker image"),
    run: bool = typer.Option(True, "--run/--no-run", "-r", help="Run the Docker container after building"),
) -> None:
    """
    Build, run, or push ROMVault Docker images.

    Examples:

        Build and run: python update.py 3.7.1

        Build WIP version: python update.py 3.7.1 --wip 1

        Push to registry: python update.py 3.7.1 --push
    """
    # Calculate version strings
    version_lower = version + (f'wip{wip}' if wip else '')
    version_upper = version + (f' WIP{wip}' if wip else '')

    # Display header
    console.print()
    console.print(Panel(
        f"[bold cyan]ROMVault {version_upper}[/bold cyan]\n"
        f"Docker Version: [yellow]{docker_version}[/yellow]\n"
        f"Tag: [green]{version_lower}[/green]",
        title="[bold magenta]🎮 ROMVault Builder[/bold magenta]",
        border_style="magenta"
    ))

    if push:
        docker_push(docker_version, version_lower, tag_latest)
    else:
        # Process template
        console.print("\n[bold blue]📝 Processing template...[/bold blue]")
        template = open_template()
        template = template.replace('{{version_lower}}', version_lower)
        template = template.replace('{{version_upper}}', version_upper)
        template = template.replace('{{docker_version}}', docker_version)
        save(template)

        # Build workflow
        if build:
            compress(version_lower)
            docker_build(docker_version, version_lower)
        if run:
            docker_run(docker_version, version_lower)

    console.print("\n[bold green]✨ Done![/bold green]\n")


if __name__ == '__main__':
    app()