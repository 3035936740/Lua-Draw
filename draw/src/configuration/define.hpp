#pragma once

namespace self {
	namespace define {
		struct UuidInfo {
			std::string uuid_namespace{};
			int64_t snowflake_twepoch{};
			int64_t snowflake_workerid{};
			int64_t snowflake_datacenterid{};
		};

		struct ExecutableFileInfo {
			std::string path{}, executable_file_name{}, directory{};
		};
	};
};
