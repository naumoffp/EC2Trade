use std::error::Error;
use std::fs::File;
use std::io::stdout;
use std::path::Path;
use std::time::Duration;

use crossterm::event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode};
use crossterm::execute;
use crossterm::terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen};
use ratatui::prelude::*;
use ratatui::widgets::{Block, Borders, Row, Table};

#[derive(Default)]
struct Price {
    availability_zone: String,
    instance_type: String,
    spot_price: String,
}

fn load_prices() -> Result<Vec<Price>, Box<dyn Error>> {
    let path = Path::new("../core/verifyprice/data/spot-price-history.csv");
    let file = File::open(path)?;
    let mut rdr = csv::Reader::from_reader(file);
    let mut prices = Vec::new();
    for result in rdr.records() {
        let record = result?;
        if record.len() >= 3 {
            prices.push(Price {
                availability_zone: record[0].to_string(),
                instance_type: record[1].to_string(),
                spot_price: record[2].to_string(),
            });
        }
    }
    Ok(prices)
}

fn run_app() -> Result<(), Box<dyn Error>> {
    enable_raw_mode()?;
    execute!(stdout(), EnterAlternateScreen, EnableMouseCapture)?;

    let backend = CrosstermBackend::new(stdout());
    let mut terminal = Terminal::new(backend)?;

    let prices = load_prices()?;

    loop {
        terminal.draw(|f| {
            let area = f.size();
            let rows = prices.iter().map(|p| {
                Row::new(vec![p.availability_zone.as_str(), p.instance_type.as_str(), p.spot_price.as_str()])
            });
            let widths = [Constraint::Length(20), Constraint::Length(15), Constraint::Length(10)];
            let table = Table::new(rows, widths)
                .header(Row::new(vec!["Availability Zone", "Instance Type", "Spot Price"]).style(Style::default().add_modifier(Modifier::BOLD)))
                .block(Block::default().borders(Borders::ALL).title("Spot Prices"));
            f.render_widget(table, area);
        })?;

        if event::poll(Duration::from_millis(200))? {
            if let Event::Key(key) = event::read()? {
                if matches!(key.code, KeyCode::Char('q') | KeyCode::Esc) {
                    break;
                }
            }
        }
    }

    disable_raw_mode()?;
    execute!(stdout(), LeaveAlternateScreen, DisableMouseCapture)?;
    Ok(())
}

fn main() -> Result<(), Box<dyn Error>> {
    if let Err(err) = run_app() {
        eprintln!("error: {err}");
    }
    Ok(())
}
