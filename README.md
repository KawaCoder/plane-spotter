
# Plane Spotter
  <p align=center>
    <a align=center href="https://www.mozilla.org/en-US/MPL/">
      <img src="https://img.shields.io/badge/License-MPL%202.0-orange.svg?style=for-the-badge&logo=mozilla" />
    </a>
    <img src="https://img.shields.io/badge/100%25-BASH-yellow.svg?style=for-the-badge&logo=linux" />
  </p>
A simple shell application that uses the OpenSky API and Open-Meteo API to evaluate if there are any planes currently visible in the sky at a given location.

## Images
![capture-of-the-script-working-in-a-shell](https://github.com/user-attachments/assets/b5d4cbc9-db1c-451c-8cbd-5121ec74db1e)

## Usage

To use the Plane Spotter application, run the following command in your terminal:

```bash
./plane_spotter.sh <latitude> <longitude>
```

### Example

To check for planes visible in the sky at the coordinates for Paris, France:

```bash
./plane_spotter.sh 48.8554 2.3459
```

## Requirements

- Bash shell
- jq ([informations here](https://packages.debian.org/bookworm/jq))
- `curl` command-line tool (for making API requests)
- Internet access
## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/plane_spotter.git
   ```

2. Navigate to the project directory:

   ```bash
   cd plane_spotter
   ```

3. Make the script executable:

   ```bash
   chmod +x plane_spotter.sh
   ```

## Contributing

Feel free to hack.

## Contact

For any inquiries or feedback, please reach out to me at [kawacoder@duck.com](mailto:kawacoder@duck.com).

## License

This project is open source and available under the [MIT License](LICENSE).
