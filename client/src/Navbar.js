import React, { Component } from "react";
import farmer from "./images/farmer.png";

class Navbar extends Component {
  render() {
    return (
      // <nav className="navbar">
      <nav className="navbar navbar-dark fixed-top bg-dark flex-md-nowrap p-0 shadow">
        <a
          className="navbar-brand col-sm-3 col-md-2 mr-0"
          href="https://www.flowglobal.net/"
          target="_blank"
          rel="noopener noreferrer"
        >
          <img
            src={farmer}
            width="30"
            height="30"
            className="d-inline-block align-top"
            alt=""
          />
          &nbsp; Flow Token Farm
        </a>

        <ul className="navbar-nav px-3">
          <li className="nav-item">
            <small className="text-secondary">
              <small id="account">{this.props.account}</small>
            </small>
          </li>
        </ul>
      </nav>
    );
  }
}

export default Navbar;
